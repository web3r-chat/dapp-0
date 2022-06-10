import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Sha2 "mo:sha2";
import Base64 "mo:encoding/Base64";
import Json "mo:json/JSON";

import Auth "auth";
import Http "http";
import Encode "encode";


actor {
    public func greet(name : Text) : async Text {
        return "Hello, " # name # "! from a Motoko backend canister.";
    };

    public shared(msg) func whoami() : async Text {
        return "Your principal is: " # Principal.toText(msg.caller);
    };

    private type PasswordSha256 = Text;
    private type DjangoSessionKey = Text;

    // HashMaps in which all the data is stored:
    // -> saved between calls to the canister, but not during upgrade, because they're not stable
    // -> we are not migrating them during upgrade, because we want to invalidate all existing logins
    // - `principalPasswords <Principal, [PasswordSha256]>`     : for each principal, a list of PasswordSha256, since multiple login flows are possible
    // - `sessionkeyPrincipal <DjangoSessionKey, Principal>`    : for each django session, the corresponding principal, which is the django username
    // - `sessionkeyPassword <DjangoSessionKey, PasswordSha256>`: for each django session, the corresponding PasswordSha256
    // - `principalMessage <Principal, Text>`                   : bot-0-action-server calls this to save the 'secret' message of a user
    private let principalPasswords = HashMap.HashMap<Principal, Buffer.Buffer<PasswordSha256>>(0, Principal.equal, Principal.hash);
    private let sessionkeyPrincipal = HashMap.HashMap<DjangoSessionKey, Principal>(0, Text.equal, Text.hash);
    private let sessionkeyPassword = HashMap.HashMap<DjangoSessionKey, PasswordSha256>(0, Text.equal, Text.hash);
    
    private let principalMessage = HashMap.HashMap<Principal, Text >(0, Principal.equal, Principal.hash);

    // Called by front end after Internet Identity Login
    public shared(msg) func session_password_create() : async Result.Result<Text, Http.StatusCode> {
        D.print("session_password_create: msg.caller = " # debug_show(msg.caller));
        switch (Auth.is_logged_in(msg.caller)) {
            case (#err statusCode) return #err(statusCode);
            case (#ok) {
                let password : Text = await Encode.random_password();
                let password_sha256 : PasswordSha256 = Encode.sha256_base64_encode(password);
                add_to_hashmap_buffer(principalPasswords, msg.caller, password_sha256);
                return #ok(password);
            };
        }  
    };

    // Called by django-server when user logs into it with username=principal & password=session_password
    // -> Called during authentication step in custom auth backend
    public shared(msg) func session_password_check(username: Text, session_password: Text) : async Result.Result<(), Http.StatusCode> {
        D.print("session_password_check: msg.caller = " # debug_show(msg.caller));
        switch (Auth.is_django_server(msg.caller)) {
            case (#err statusCode) return #err(statusCode);
            case (#ok) {
                let password_sha256 : PasswordSha256 = Encode.sha256_base64_encode(session_password);
                return in_hashmap_buffer(principalPasswords, Principal.fromText(username), password_sha256);
            };
        }  
    };

    // Called by django-server when front end logs into it with username=principal & password=session_password
    // -> Called after succesfull login, to store django's session_key for cleanup purposes upon logout
    public shared(msg) func save_django_session_key(django_session_key: Text, username: Text, session_password: Text) : async Result.Result<(), Http.StatusCode> {
        D.print("save_django_session_key: msg.caller = " # debug_show(msg.caller));
        switch (Auth.is_django_server(msg.caller)) {
            case (#err statusCode) return #err(statusCode);
            case (#ok) {
                let password_sha256 : PasswordSha256 = Encode.sha256_base64_encode(session_password);
                switch (in_hashmap_buffer(principalPasswords, Principal.fromText(username), password_sha256)){
                    case (#err statusCode) return #err(statusCode);
                    case (#ok) {
                        sessionkeyPrincipal.put(django_session_key, Principal.fromText(username));
                        sessionkeyPassword.put(django_session_key, password_sha256);
                        return #ok;
                    };
                }
                
            };
        }  
    };
    
    // Called by django-server when user logs out
    public shared(msg) func session_password_delete(django_session_key: Text) : async Result.Result<(), Http.StatusCode> {
        D.print("session_password_delete: msg.caller = " # debug_show(msg.caller));
        switch (Auth.is_django_server(msg.caller)) {
            case (#err statusCode) return #err(statusCode);
            case (#ok) {
                switch (sessionkeyPrincipal.get(django_session_key)) {
                    case (?principal) {
                       switch (sessionkeyPassword.get(django_session_key)) {
                            case (?password_sha256) {
                                sessionkeyPrincipal.delete(django_session_key);
                                sessionkeyPassword.delete(django_session_key);
                                return delete_from_hashmap_buffer(principalPasswords, principal, password_sha256);
                            };
                            case null {
                                D.print(debug_show("password_sha256 not found in sessionkeyPassword"));
                                return #err(Http.Status.Unauthorized);
                            };
                        };
                    };
                    case null {
                        D.print(debug_show("principal not found in sessionkeyPrincipal"));
                        return #err(Http.Status.Unauthorized);
                    };
                };
            };
        }  
    };

    // Called by bot-0-action server
    public shared(msg) func save_message(principal: Text, message: Text) : async Result.Result<(), Http.StatusCode> {
        D.print("save_message: msg.caller = " # debug_show(msg.caller));
        switch (Auth.is_bot_0_action_server(msg.caller)) {
            case (#err statusCode) return #err(statusCode);
            case (#ok) {
                principalMessage.put(Principal.fromText(principal), message);
                return #ok;
            };
        }  
    };

    // Public, to be called by user during bot-0's smartcontract demo
    public shared(msg) func get_message(principal: Text) : async ?Text {
        return principalMessage.get(Principal.fromText(principal));
    };

    // Helper functions for HasMaps that store a Buffer
    func add_to_hashmap_buffer(hashmap: HashMap.HashMap<Principal, Buffer.Buffer<Text>>, principal: Principal, value: Text) {
        switch (hashmap.get(principal)) {
            case (?buffer) {
                buffer.add(value);
            };
            case null {
                let buffer = Buffer.Buffer<Text>(0);
                buffer.add(value);
                hashmap.put(principal, buffer);
            };
        };
    };

    func in_hashmap_buffer(hashmap: HashMap.HashMap<Principal, Buffer.Buffer<Text>>, principal: Principal, value: Text) : Result.Result<(), Http.StatusCode> {
        switch (hashmap.get(principal)) {
            case (?buffer) {
                for (i in Iter.range(0,buffer.size()-1)) {
                    if (buffer.get(i) == value) {
                        return #ok
                    };
                };
                return #err(Http.Status.Unauthorized);
            };
            case null {
                return #err(Http.Status.Unauthorized);
            };
        };
    };

    func delete_from_hashmap_buffer(hashmap: HashMap.HashMap<Principal, Buffer.Buffer<Text>>, principal: Principal, value: Text) : Result.Result<(), Http.StatusCode> {
        switch (hashmap.get(principal)) {
            case (?buffer) {
                var found_it = false;
                for (i in Iter.range(0,buffer.size()-1)) {
                    if (buffer.get(i) == value) {
                        D.print(debug_show("Found a matching value..."));
                        D.print(debug_show("Setting it to LOGGED-OUT..."));
                        buffer.put(i, "LOGGED-OUT");
                        found_it := true;
                    };
                };
                if (found_it) {
                    // Once all sessions for this principal are logged out, clear the buffer
                    for (i in Iter.range(0,buffer.size()-1)) {
                        if (buffer.get(i) != "LOGGED-OUT") {
                            return #ok;
                        };
                    };
                    D.print(debug_show("All sessions for this principal are LOGGED-OUT. Clearing buffer..."));
                    buffer.clear();
                    return #ok;
                };
                return #err(Http.Status.Unauthorized);
            };
            case null {
                D.print(debug_show("buffer does not exist..."));
                return #err(Http.Status.Unauthorized);
            };
        };
    };
};


// 
// NOT USED, BUT SAVE AS A REFERENCE
// Deploy like this, to pass in a secret token:
// $ dfx deploy canister_motoko --argument '("this-is-a-secret-token")'
// 
// Upon logout, frontend must call a method here to remove the Jwt for a principal
// Logout is done in Navbar.jsx - TogglerNavLinks
// 
// shared(msg) actor class Jwt(secret_token : Text) {
//  
//     private let _owner : Principal = msg.caller;
//     private let _secret_token : Text = secret_token;
// 

// Authentication & Authorization

import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Http "http";
import Json "mo:json/JSON";

module {
    
    public func is_logged_in(p: Principal) : Result.Result<(), Http.StatusCode> {
        if (Principal.isAnonymous(p)){
            return #err(Http.Status.Unauthorized);
        };
        return #ok;
    };

    public func is_django_server(p: Principal) : Result.Result<(), Http.StatusCode> {
        if (Principal.isAnonymous(p)){
            return #err(Http.Status.Unauthorized);
        };

        // The principal of the django_server.
        // See README of django-server
        let _django_server_principal : Principal = Principal.fromText("umz5m-qascs-utlgq-ubxaw-gbg5t-3aq6i-ndroa-kptza-6cimu-b2oqt-iae");
        if (Principal.notEqual(p, _django_server_principal)) {
            return #err(Http.Status.Unauthorized);
        };

        return #ok;
    };

    public func is_bot_0_action_server(p: Principal) : Result.Result<(), Http.StatusCode> {
        if (Principal.isAnonymous(p)){
            return #err(Http.Status.Unauthorized);
        };

        // The principal of bot_0_action_server.
        // See README of bot-0
        let _bot_0_action_server_principal : Principal = Principal.fromText("zndgs-apb3e-afc4j-d4bhj-ckavb-ltzpx-udrtv-timqx-mbhde-exzek-lqe");
        if (Principal.notEqual(p, _bot_0_action_server_principal)) {
            return #err(Http.Status.Unauthorized);
        };

        return #ok;
    };
};
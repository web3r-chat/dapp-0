// Methods for JWT creation during login flow

import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Random "mo:base/Random";
import Nat8 "mo:base/Nat8";

import Base64 "mo:encoding/Base64";
import Sha2 "mo:sha2";

module {
    public func random_password(): async Text {
        // https://crypto.unibe.ch/archive/theses/2020.bsc.michael.senn.pdf ; section C.1
        let randomBlob : Blob = await Random.blob();
        let pw : Text = base64_encode_blob(randomBlob);
        
        return pw;
    };

    func base64_encode_blob(in_blob: Blob): Text {
        let in_array : [Nat8] = Blob.toArray(in_blob);
        let out_array : [Nat8] = Base64.encode(in_array);
        let out_blob : Blob = Blob.fromArray(out_array);
        let out_text : ?Text = Text.decodeUtf8(out_blob);
        return Option.get(out_text, "");
    };

    func base64_encode_text(in_text: Text): Text {
        let in_blob : Blob = Text.encodeUtf8(in_text);
        return base64_encode_blob(in_blob);
    };

    public func sha256_base64_encode(in_text: Text): Text {
        let in_blob : Blob = Text.encodeUtf8(in_text);
        let out_blob : Blob = Sha2.fromBlob(#sha256, in_blob);
        let out_text : Text = base64_encode_blob(out_blob);
        return out_text;
    };
};
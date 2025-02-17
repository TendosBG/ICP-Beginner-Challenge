import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Map "mo:map/Map";
import Vector "mo:vector";
import {phash; nhash }"mo:map/Map";

actor {
    stable var nextId : Nat = 0;
    stable var userIdMap : Map.Map<Principal, Nat> = Map.new<Principal, Nat>();
    stable var userProfileMap : Map.Map<Nat, Text> = Map.new<Nat, Text>();
    stable var userResultsMap : Map.Map<Nat, Vector.Vector<Text>> = Map.new<Nat, Vector.Vector<Text>>();
    
    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text;}, Text> {
        let userID = switch (Map.get(userIdMap, phash, caller)) {
            case (?id) { id };
            case (_) { return #err("User not found") };
        };

        let name = switch (Map.get(userProfileMap, nhash, userID)) {
            case (?name) { name };
            case (_) { return #err("Username not found") };
        };

        return #ok({ id = userID; name = name });
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        Debug.print(debug_show caller);
        var idRecorded = 0;
        switch (Map.get(userIdMap, phash, caller)) {
            case (?idFound) {
                Map.set(userIdMap, phash, caller, idFound);
                Map.set(userProfileMap, nhash, idFound, name);
                idRecorded := idFound;
            };
            case (_) {
                Map.set(userIdMap, phash, caller, nextId);
                Map.set(userProfileMap, nhash, nextId, name);
                idRecorded := nextId;
                nextId += 1;
            };
        };
        return #ok({ id = idRecorded; name = name });        
        
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userID = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) found;
            case (_) { return #err("User not found") };
        };

        let results = switch (Map.get(userResultsMap, nhash, userID)) {
            case (?found) found;
            case (_) { Vector.new<Text>() };
        };

        Vector.add(results, result);
        Map.set(userResultsMap, nhash, userID, results);

        return #ok({ id = userID; results = Vector.toArray(results) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        
        let userID = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) found;
            case (_) { return #err("User not found") };
        };

        let results = switch (Map.get(userResultsMap, nhash, userID)) {
            case (?found) found;
            case (_) { Vector.new<Text>() };
        };

        return #ok({ id = userID; results = Vector.toArray(results) });
    };

    public query func getAllUsers() : async Result.Result<{ users : [{ id : Nat; name : Text }] }, Text> {
    var allUsers : [{ id : Nat; name : Text }] = [];
    
    for (entry in Map.entries(userProfileMap)) {
        let id = entry.0;
        let name = switch (Map.get(userProfileMap, nhash, id)) {
            case (?name) { name };
            case (_) { return #err("User profile not found") };
        };

        allUsers := Array.append(allUsers, [{ id = id; name = name }]);
    };

    return #ok({ users = allUsers });
    };
};

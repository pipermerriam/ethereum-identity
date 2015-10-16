contract IdentityHub {
}


contract Pool {
        uint public identityFee;

        function Pool(uint identityFee) {
                if (identityFee < 1 ether) {
                        // The minimum fee needs to be sufficiently large
                        // to motivate attackers to exploit weaknesses, but
                        // still small enough that it is easy for any
                        // individual to pay.  This should probably be it's own
                        // sub-currency (SybilCoin?)
                        throw;
                }
                identityFee = identityFee;
        }

        // counter for giving identity requests id's
        uint requestCounter;

        struct IdentityRequest {
                // Unique Identifier
                uint id;

                // Owner
                address owner;

                // Fee
                uint fee;

                // Timestamps
                uint requestedAt;
                uint acceptedAt;
                uint rejectedAt;

                // Identity contract
                Identity identity;
        }

        // Running total of the number of identities in this pool.
        uint public identityCount;

        struct Identity {
                // Unique Identifier
                bytes32 id;

                // The id of the IdentityRequest which resulted in the creation
                // of this identity.
                uint requestId;

                // Identity owner
                address owner;

                // Timestamps
                uint createdAt;

                // The id of the proof which destroys this identity.
                uint proofId;
        }

        // Stores mapping of requestId to IdentityRequest
        mapping (uint => IdentityRequest) requests;

        // Stores whether an identity id has already been issued.
        mapping (bytes32 => bool) issued_ids;

        // Mapping from identity id to Identity contract.
        mapping (bytes32 => Identity) identities;

        // Mapping of addresses to identities.
        mapping (address => bytes32) addr_to_identity;

        function requestIdentity() {
                if (msg.value < identityFee) {
                        msg.sender.send(msg.value);
                        return;
                }

                var request = requests[requestCounter];

                request.id = requestCounter;
                request.owner = msg.sender;
                request.fee = msg.value;
                request.requestedAt = now;

                requestCounter++;
        }

        function acceptRequest(uint requestId, bytes32 identityId) {
                var request = requests[requestId];

                // Validation
                if (request.id != requestId) {
                        return;
                }
                if (request.rejectedAt > 0) {
                        // Already rejected.
                        return;
                }
                if (request.acceptedAt > 0) {
                        // Already accepted
                        return;
                }
                if (issued_ids[identityId]) {
                        // An identity already exists for this pool with the
                        // provided identityId.
                        return;
                }

                issued_ids[identityId] = true;

                addr_to_identity[request.owner] = identityId;

                request.acceptedAt = now;
                request.identity = identities[identityId];

                request.identity.id = identityId;
                request.identity.owner = request.owner
                request.identity.requestId = requestId;
                request.identity.createdAt = now;
        }

        function rejectRequest(uint requestId) {
                var request = request[requestId];

                // Validation
                if (request.id != requestId) {
                        // Invalid request id.
                        return;
                }
                if (request.acceptedAt > 0) {
                        // Already accepted
                        return;
                }
                if (request.rejectedAt > 0) {
                        // Already rejected.
                        return;
                }
                // Send back their ether.
                request.rejectedAt = now;

                // TODO: the requester should not get all of their money back
                // (maybe half).  The other half should potentially be
                // distributed back to the pool members as re-imbursment for
                // their fee.  This reimbursment should be accounted for in the
                // event that the member participates in a proof..
                request.owner.gas(msg.gas)(value)
        }

        /*
         *  Sybil proofs
         */
        uint proofCounter;

        // Window of time for each proof that secondary identities are allowed
        // to join the proof.
        uint constant PROOF_ENROLLMENT_WINDOW = 60 minutes;
        uint constant PROOF_CLAIM_WINDOW = 60 minutes;
        uint constant PROOF_DEPOSIT = 1 ether;

        struct Proof {
                // Identifier
                uint id;

                // The identity id that initiated this proof
                bytes32 primaryIdentityId;

                // The additional identities that are participating in the
                // proof.
                bytes32[] secondaryIdentityIds;

                // Each participating identity must put down a deposit so that
                // they have something at stake.
                uint deposit;

                // Timestamps
                uint createdAt;

                // Identities that have claimed the proof reward
                bytes32[] claims;
        }

        mapping (uint => Proof) proofs;
        mapping (bytes32 => uint) identity_to_proof;

        function initiateProof() {
                bytes32 identityId = addr_to_identity[msg.sender];
                if (identityId == 0x0) {
                        // This address does not have any identity assiciated
                        // with it.
                        return;
                }

                if (msg.value < PROOF_DEPOSIT) {
                        // Insufficient deposit so send it back.
                        msg.sender.gas(msg.gas)(value);
                        return;
                }

                var identity = identities[identityId];

                if (identity.proofId != 0) {
                        // This identity has already participated in a proof
                        // and thus cannot participate in any other proofs.
                        return;
                }

                var proof = identity_to_proof[identityId];

                if (proof.id != 0) {
                        // Once an identity has added itself to a proof, it
                        // cannot participate in any other proof.
                        return;
                }

                // Increment the proof counter
                proofCounter += 1;

                // Initialize the proof.
                proof.id = proofCounter;
                proof.primaryIdentityId = identityId;
                proof.deposit = msg.value;
                proof.createdAt = now;
        }

        function joinProof(uint proofId) {
                bytes32 identityId = addr_to_identity[msg.sender];
                if (identityId == 0x0) {
                        // This address does not have any identity assiciated
                        // with it.
                        return;
                }

                if (msg.value < PROOF_DEPOSIT) {
                        // Insufficient deposit so send it back.
                        msg.sender.gas(msg.gas)(value);
                        return;
                }

                var identity = identities[identityId];

                if (identity.proofId != 0) {
                        // This identity has already participated in a proof
                        // and thus cannot participate in any other proofs.
                        return;
                }

                var proof = identity_to_proof[identityId];

                if (proof.id == 0) {
                        // Invalid proof id
                        return;
                }

                if (proof.createdAt + PROOF_ENROLLMENT_WINDOW < now) {
                        // Enrollment window for proof has expired.
                        return;
                }

                // Add the identity to the proof
                proof.secondaryIdentityIds.length += 1;
                proof.secondaryIdentityIds[proof.secondaryIdentityIds.length - 1] = identityId;
        }

        function claimReward(uint proofId) {
                bytes32 identityId = addr_to_identity[msg.sender];
                if (identityId == 0x0) {
                        // This address does not have any identity assiciated
                        // with it.
                        return;
                }

                var identity = identities[identityId];

                if (identity.proofId != 0) {
                        // This identity has already participated in a proof
                        // and thus cannot participate in any other proofs.
                        return;
                }
        }
}

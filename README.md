# Introduction

This repository is an experimental anti-sybil system named Odin.

The name Odin comes from the chief god of Norse mythology is referred to by
more than 200 names, which seems to be a fitting name for a system which
attempts to solve the problem of knowing whether the entity you are interacting
with is already known to you by another name.

See https://github.com/ethereum/wiki/wiki/Problems#14-anti-sybil-systems for a
detailed write-up of the problem.

## Goals

The goals of this system are as follows.

- Decentralization: No dependency on a central authority for the system to work.
- Cost to individuals to obtain an identity is low.
- Cost to individuals to obtaining multiple identities is high.
- Cost to automated systems to obtaining multiple identities is high.

## Definitions

- **Odin**

The name of this anti-sybil system.

- **entity**

The term entity is used to refer to one of more individuals who are operating
as a single unit.

- **individual**

The term individual is used to refer to a singular person or address.

- **identity pool**

A pool is a set of identities.  Normally referred to using the shorthand **pool**

- **issuer**

Each pool is run by an issuer who is the sole distributor or identities for
that pool.  The term **operator** is sometimes used to refer to the entity that
issues identities for a pool.

- **operator**

Alias for the **issuer** of identities for a pool.

- **identity**

A member of a pool, identified by an identifier which is unique for that pool
and owned by an ethereum address.

- **identity fee**

The cost of getting an identity issued.  This value can differ from pool to pool.

- **sybil fund**

A monitary fund within each pool that is paid for with identity fees.

- **sybil proof**

The act of multiple identities with a pool revealing that they are operated by
the same entity.

- **proof reward**

A monitary reward for successful sybil proofs.

- **proof secret**

A secret value that is committed to at the initiation of a sybil proof, and
revealed at the end of the proof.

- **secret hash**

The `sha3` hash of a secret, possibly combined with other data which commits
the submitter to a value without revealing that value.


# Overview

Odin consists of a set of identity pools.  Each pool is run by an entity who
acts as the sole issuer of identities for that pool.  Anyone may create and
operate a pool.

## How pools issue identities.

The issuer for each pool may issue identities as they see fit.  Each identity
issued must be assigned a unique identifier which is chosen by the issuer and
is required to be unique within the given pool.

* Some pools may decide to enact very strict rules for identity issuance such
  as requiring verification of a passport
* while others may choose to enact no rules and issue identities with
  no verification.

The **facebook** pool for example, may choose to issue a single identity for
each facebook account.  In this pool, the rules for getting an identity issued
are simply that you must have a facebook account.

A company may create a pool and issue identies to each of it's employees.
Under this model, each new employee would be issued an identity.

The government of a country running a pool may choose to issue identities based
on passport or drivers licence numbers where each identity corresponds to one
of these document that has been verified by some government department.

## Issuance Fee

When an entity requests an identity from a pool, they must include a fee with
their request.  A portion of this fee is given to the pool operator as a fee,
and a portion is placed into the sybil fund for the pool.

## Identities

Each identity may choose to associate additional addresses with their identity.
This allows them to *link* and identity from one pool with an identity from
another pool.

## Sybil Proofs

At any time, two or more identities within a pool can choose to participate in
a sybil proof, revealing that they are being operated by the same entity.  A
successful proof pays the proof reward to the addresses of the participating
identities.  A sybil proof is considered successful if 2 or more identities
participate.  Participation in a proof destroys the participating identity.  

### Maximum Proof Size

Any proof may only have a maximum of `max(2, floor(sqrt(num_members)))`
participants where `num_members` is the number of members currently in the
pool.

This mechanism adds an upper bound to the number of identities any entity will
try to include in a given proof.  The payout amount for a proof increases with
each additional participant, so it is useful to have this value be bounded as
it ensures that sybil proofs will remain profitable as long as a pool continues
to grow in size.

### Proof Stages

A sybil proof occurs in 4 stages.

#### Stage 1. - Initiation

Any account may initiate a sybil proof at any time.  Initiation requires the following:

- a deposit, which will be refunded if the proof is successful.
- a proof-secret hash which is the `sha3(proof_secret)` of a secret that will
  be revealed during stage 3.

#### Stage 2. - Enrollment

During stage 2 any other identity may enroll as a participant of this proof by
providing the following.

- a deposit, which will be refunded if the proof is successful.
- an enrollment-secret hash which is the `sha3(identity_id, secret)` where
  `secret` is the proof-secret submitted during the initiation phase.

#### Stage 3. - Proof

During stage 3 any address related to one of the participating identities who
can *prove* they know the proof-secret can initiate a payment claim for the
proof. A proof is considered successful at this point if two or more identities
participated in the proof.

The payment is computed as the sum of all deposits submitted for the proof, the
issuance fees for all participating identities, and the proof-reward value.

#### Stage 4. - Payment

After a short waiting period, if no other claims are submitted, a claimer may
initiate payment which transfers the proof payment to their address and
finalizes the proof.

If at any time during the waiting period a new claim comes in from another
participating identity that has not already initiated a claim, the initial
claim is cancelled and replaced by the new claim.

#### Preventing collusion on proofs

The goal of sybil proofs is to expose weaknesses where independent individuals
are able to acquire more than one identity in a given pool.  In order to
de-incentivize any collusion by separate individuals, two mechanisms are in
place to make it difficult for disparate individuals to trust each other.

#### Secret Sharing

In order for a proof to be successful, the individual who initiates the proof
must share their secret with any other identity that is going to participate in
the proof so that they can calculatethe enrollment-secret.

If the participating identities, trust the initiatior of the proof to compute
this hash for them, then it is possible for the initiator to provide them with
an incorrect hash which will allow the initiator to take their deposit since
their hash will not verify in stage 3.

Additionally, during stage 2 anyone who can *prove* they know the proof-secret can claim all
of the submitted deposits, which allows any participant to steal all of the
deposits.

#### Payment Claiming

If at any time during the waiting period a new claim comes in from another
participating identity that has not already initiated a claim, the initial
claim is cancelled and replaced by the new claim.  Each time this occurs, the
overall payment amount adjusted by a multiplier defined as `2 / (N + 1)` whe N
is the total number of claims for this proof.

This exposes another mechanism through which participants can steal from each
other.  Each successive claim allows the individual to claim more of the
payment than they would have received were it to have been split evenly, while
simultaneously reducing the overall payout.


### Proof Reward Schedule

> The exact formulas

The reward for a sybil proof dynamically computed based on various properties
of the pool.  The formula is:

`BaseReward * ProofSizeMultiplier * PoolStateMultiplier`

This formula is designed to have the following economical incentives.

- As long as a pool is growing sybil proofs will be profitable.
- For each proof size, successive sybil-proofs become linearly less profitable,
  eventually reaching zero.
- Pools with very few sybil proofs (difficult to get multiple identities) will
  have larger proof rewards.
- Pools with very many sybil proofs (easy to get multiple identities) will have
  smaller or zero reward for proofs.

This system effectively sets up a marketplace where there is an encouraged
financial incentive for entities to expose weaknesses in an issuer's identity
verification scheme.

#### BaseReward

The `BaseReward` variable is computed as `sybil_fund / member_count` where:

- `sybil_fund`: the amount available in the sybil-fund to pay for sybil proofs
- `member_count`: the number of members in the pool.

For a pool which has had zero sybil proofs, this value is equal to the portion
of the issuance fee that goes into the sybil fund.  As more sybil-proofs occur,
this value drops towards a lower bound of zero.

#### Proof Size Multiplier

The `ProofSizeMultiplier` variable is computed as `1 - 1 / proof_size` where
`proof_size` is the number of identities participating in the proof.

This multiplier starts at `0.5` and approaches `1` asymptotically as the number
of participants increases.  This incentivises larger proof sizes while making
the incremental value of each successive proof size drop quickly.

#### Pool State Multiplier

The `PoolStateMultiplier` variable is computed as 

`1 - min(total_sybil_accounts, member_count) / member_count`

where:

- `total_sybil_accounts` is the number of accounts that have been destroyed in
  sybil proofs who's number of participants was greater than or equal to the
  number of participants in this proof.
- `member_count` is the number of members currently in the pool.

This multiplier starts at `1` for the first sybil-proof for each number of
participants, and then drops linearly towards zero for each successive proof of
the same size.

Each time someone successfully submits a sybil-proof of a new higher value,
they are again rewarded 100% of the bonus.

## Deriving Uniqueness

TODO: this needs to be worked out.

Odin does not provide a single source of identity uniqueness verification, but
rather provides a network through which anyone wishing to verify the uniqueness
for an identity can query.

Each entity that wishes to know about the uniqueness of an individual will
likely select a set of pools from which they choose to trust and not allow
registration from identities which are not registered with one or more of the
pools.

## Bad Behavior

### Puppet Pools

An entity could set up a pool, and register many accounts with it, while in
reality, the entire pool and the identities registered with it are really
controlled by a single individual or entity.

Odin provides direct no protection against this sort of attack since Odin is
not in the business of trust.  For this puppet pool to be useful in any way, it
would need to convince others to use it as a source of trust which while not
impossible, is very unlikely.

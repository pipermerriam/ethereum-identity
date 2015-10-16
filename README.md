# Introduction

This repository is an experimental anti-sybil system named Odin.

The name Oden comes from the chief god of Norse mythology is referred to by
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

- **Oden**

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

Oden consists of a set of identity pools.  Each pool is run by an entity who
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

## Sybil Proofs

At any time, two or more identities within a pool can choose to participate in
a sybil proof, revealing that they are being operated by the same entity.  A
successful proof pays the proof reward to the addresses of the participating
identities.  A sybil proof is considered successful if 2 or more identities
participate.  Participation in a proof destroys the participating identity.

### Proof Stages

A sybil proof occurs in three stages.

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

During stage 2 anyone who can *prove* they know the proof-secret can claim all
of the submitted deposits.  When this occurs, the proof is considered a
failure.

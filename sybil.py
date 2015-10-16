import math
import decimal
import collections
import random


p = {
    'member_count': 1000,
    'deposit_size': 1,
    'account_balance': 1000,
    'proofs': collections.defaultdict(int),
}


class Pool(object):
    def __init__(self, member_count, deposit_size=1, account_balance=None, proofs=None):
        if account_balance is None:
            account_balance = member_count * deposit_size

        if proofs is None:
            proofs = collections.defaultdict(int)

        self.member_count = member_count
        self.deposit_size = deposit_size
        self.account_balance = account_balance
        self.proofs = proofs

    def get_effective_deposit(self):
        """
        The deposit amount as derived from the account balance.  As a pool gets
        more sybil proofs, the effective deposit goes down, thus reducing the
        reward for attacking.
        """
        return self.account_balance * 1.0 / self.member_count

    def get_max_proof_size(self):
        """
        When a pool is really small, it isn't interesting to see that people
        can get 1000's of accounts.  Hence we keep this number small with
        respect to the total pool size.

        10         : 3
        100        : 10
        1,000      : 31
        10,000     : 100
        100,000    : 316
        1,000,000  : 1000
        """
        return max(2, int(math.sqrt(self.member_count)))

    def get_base_bonus(self, proof_size):
        """
        Profit goes up as proof
        """
        ps = int(min(proof_size, self.get_max_proof_size()))
        return self.get_effective_deposit() * (ps - 1) ** 2 / (ps)

    def get_total_proofs(self, proof_size):
        return sum(v for k, v in self.proofs.items() if k >= proof_size)

    def get_bonus_multiplier(self, proof_size):
        """
        As a pool's number of sybil proofs goes up with respect to it's member
        size, the sybil proof bonus needs to go down, eventually hitting zero
        at a certain point.

        """
        tp = self.get_total_proofs(proof_size)
        return 1 - min(tp, self.member_count) / self.member_count

    def get_sybil_proof_value(self, proof_size):
        return self.get_base_bonus(proof_size) * self.get_bonus_multiplier(proof_size)

    def apply_sybil_proof(self, proof_size):
        if self.member_count <= 0:
            raise ValueError
        value = self.get_sybil_proof_value(proof_size)
        if value <= 0:
            raise ValueError

        self.account_balance -= value + (proof_size * self.deposit_size)
        self.proofs[proof_size] += 1
        self.member_count -= proof_size
        self.member_count = max(0, self.member_count)
        return value

    def join(self):
        self.member_count += 1
        self.account_balance += self.deposit_size


def simulate_pool_growth(to_size=1000000, difficulty_rating=1.01):
    """
    Choices
    - attack pool (prob based on value) (success based on difficulty_rating)
    - join pool
    """
    pool = Pool(0, 1)
    generation = 0
    width = int(math.ceil(math.log10(to_size)))

    while pool.member_count < to_size:
        print "Generation: {0}".format(generation)
        generation += 1

        ps_average = max([1] + pool.proofs.keys())
        ps = int(random.triangular(2, min(pool.get_max_proof_size(), ps_average + 1)))

        if pool.member_count:
            attack_value = pool.get_base_bonus(ps)
        else:
            attack_value = 0
        p_attack = 1 - 1 / random.uniform(1, 1 + 10 * float(attack_value))
        p_join = 1 - p_attack

        c = random.uniform(0, 1)
        if c < p_join:
            pool.join()
            print "{0} > member joined".format(str(pool.member_count).ljust(width))
        else:
            success = 1 / random.uniform(1, difficulty_rating)
            if random.uniform(0, 1) < success:
                try:
                    for _ in range(int(ps)):
                        pool.join()
                    value = pool.apply_sybil_proof(ps)
                except ValueError:
                    continue
                print "{0} > sybil proof success: {1}".format(
                    str(pool.member_count).ljust(width),
                    decimal.Decimal(value).quantize(decimal.Decimal('1.000')),
                )
                continue
            print "{0} > sybil proof failure".format(str(pool.member_count).ljust(width))
    return pool

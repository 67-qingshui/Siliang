import Foundation

// 割り勘 settlement: computes who owes whom and net balances.
// v2: 先算净额 (net), 再做最小化转账抵消, 只输出必须发生的转账.
enum SettlementEngine {

    struct Transfer: Identifiable, Hashable {
        let id = UUID()
        var debtor: UUID      // 付钱的人 (欠钱)
        var creditor: UUID    // 收钱的人 (被欠)
        var amount: Double
    }

    struct Result {
        var transfers: [Transfer]   // 净额抵消后的最少转账 (amount > 0)
        var nets: [UUID: Double]    // member -> net (positive = receivable, negative = payable)
    }

    static func compute(expenses: [SplitExpense], repayments: [Repayment], members: [Member]) -> Result {
        // 1) 累加原始债务: 每人 -> 每人 欠多少
        var net: [UUID: Double] = [:]

        for e in expenses {
            let payer = e.paidBy
            var shares: [UUID: Double] = [:]

            switch e.splitMode {
            case .equal:
                let pids = e.shares.map(\.memberId)
                let count = max(pids.count, 1)
                let share = e.amount / Double(count)
                for pid in pids { shares[pid] = share }
            case .custom:
                for s in e.shares where s.amount > 0 { shares[s.memberId] = s.amount }
            }

            for (pid, share) in shares where pid != payer {
                switch e.direction {
                case .expense:
                    // participant owes the payer
                    net[payer, default: 0] += share      // payer 应收
                    net[pid, default: 0] -= share        // participant 应付
                case .income:
                    // payer distributes income to participants
                    net[pid, default: 0] += share
                    net[payer, default: 0] -= share
                }
            }
        }

        for r in repayments {
            net[r.to, default: 0] += r.amount
            net[r.from, default: 0] -= r.amount
        }

        // 2) 净额抵消 -> 最少转账 (greedy matching)
        var creditors = net.filter { $0.value > 0.01 }   // 应收 (positive)
        var debtors   = net.filter { $0.value < -0.01 }  // 应付 (negative)

        var transfers: [Transfer] = []
        // 按金额降序匹配, 大额优先, 结果更接近最少笔数
        let creditorOrder = creditors.keys.sorted { creditors[$0]! > creditors[$1]! }
        let debtorOrder   = debtors.keys.sorted { debtors[$0]! < debtors[$1]! }

        var ci = 0, di = 0
        while ci < creditorOrder.count && di < debtorOrder.count {
            let c = creditorOrder[ci]
            let d = debtorOrder[di]
            let credit = creditors[c]!
            let debt = -debtors[d]!
            let amount = min(credit, debt)

            if amount > 0.01 {
                transfers.append(Transfer(debtor: d, creditor: c, amount: amount))
            }

            creditors[c] = credit - amount
            debtors[d] = debtors[d]! + amount

            if credit - amount <= 0.01 { ci += 1 }
            if debt - amount <= 0.01 { di += 1 }
        }

        return Result(transfers: transfers, nets: net)
    }
}

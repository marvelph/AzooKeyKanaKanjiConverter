//
//  kana2kanji.swift
//  Kana2KajiProject
//
//  Created by ensan on 2020/09/02.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
public typealias PValue = Float16
#else
public typealias PValue = Float32
#endif

struct Kana2Kanji {
    var dicdataStore: DicdataStore

    /// CandidateDataの状態からCandidateに変更する関数
    /// - parameters:
    ///   - data: CandidateData
    /// - returns:
    ///    Candidateとなった値を返す。
    /// - note:
    ///     この関数の役割は意味連接の考慮にある。
    func processClauseCandidate(_ data: CandidateData) -> Candidate {
        let mmValue: (value: PValue, mid: Int) = data.clauses.reduce((value: .zero, mid: MIDData.EOS.mid)) { result, data in
            (
                value: result.value + self.dicdataStore.getMMValue(result.mid, data.clause.mid),
                mid: data.clause.mid
            )
        }
        let text = data.clauses.reduce(into: "") { $0.append($1.clause.text) }
        let value = data.clauses.last!.value + mmValue.value
        let lastMid = data.clauses.last!.clause.mid

        let composingCount: ComposingCount = data.clauses.reduce(into: .inputCount(0)) {
            for range in $1.clause.ranges {
                $0 = .composite($0, range.count)
            }
        }
        var candidate = Candidate(
            text: text,
            value: value,
            composingCount: composingCount,
            lastMid: lastMid,
            data: data.data
        )
        if data.clauses.count > 1 {
            var start = data.data.startIndex
            candidate.clauses = data.clauses.map { unit in
                let clause = unit.clause
                let end = min(data.data.endIndex, max(start, clause.dataEndIndex + 1))
                defer { start = end }
                return Candidate(
                    text: clause.text,
                    value: unit.value,
                    composingCount: clause.ranges.reduce(.inputCount(0)) { .composite($0, $1.count) },
                    lastMid: clause.mid,
                    data: Array(data.data[start..<end])
                )
            }
        }
        return candidate
    }
}

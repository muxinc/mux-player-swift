//
//  Examples.swift
//  MuxPlayerSwiftExample
//
//  Created by Emily Dixon on 4/24/24.
//

import Foundation

struct DRMExample {
    let title: String
    let playbackID: String
    let playbackToken: String
    let drmToken: String
}

extension DRMExample {
    static let DRM_EXAMPLES = [
        DRMExample(
            title: "Staging test PlaybackID 1",
            playbackID: "UHMpUMz4l00SmDcgAAQPd4Yk01200IDwD4uD7K24GPp01yg" ,
            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzIyNjE2OTc0LCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6IlVITXBVTXo0bDAwU21EY2dBQVFQZDRZazAxMjAwSUR3RDR1RDdLMjRHUHAwMXlnIn0.rDymk2prKKDqlSKMnWDl24YNQ_LfnPlEzkBFr2-M3Yb_0mABE_bp-a2NeIKgwmqPxSvS0VAXpJApMbNa1j43yzW8oQxyZZXWnw0NLTQfdKfafDs83JVJB7uhL7MeEXcs1lpJGwLPSDYwdIPt2dKNzbATjqRViYbUO4GF14cq_35xsCb-kZy4D42_pdn62K6XnDUqccEeUmBav8W7m8ZILZ4eBJJJdCGVB9B85uGse_YTokGrXZ-chVO-uZ328B6ns_ehnhbJPtpstmUHvaqo0Xf0qF1J7pKkpbVoMwyhERB6M70m3oijP2GM1kLKAayrh1ujmNRNTXLcRJeBobqmPg",
            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzIyNjE2OTE0LCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6IlVITXBVTXo0bDAwU21EY2dBQVFQZDRZazAxMjAwSUR3RDR1RDdLMjRHUHAwMXlnIn0.tHmqMgHf3pY2adP9QVvx9VIUVZvaxzWZP8Qf4DSUBnT4Zxac-tRPBsHDtBlFIILhmPhjBa2IAmD2PdqgHopSxw_zDp9ktTl6QAKCGgw40ZUKt4GD4aZKubKzAyfPm5q0-7f8aW8oNDbejQ1VjN5QqIBb50ytyPc4NkIzwqJ3P3azrr4TSlo-NiXbXhwWuiMHGqspoNPk8BGBcXpSML7vghlncxwKWYAwbpPaz5q5AEMmN5sqKo7woSVsXBxoe78al6cfT2SRdDR6bu92kMf5zSZ9600boNSjmNn2Dx5IidFAZMYy9qVj22W1T-7rCthmc37c9OcUGK9g0unHEAFE6A"
        ),
        DRMExample(
            title: "Staging Test PlaybackID 2",
            playbackID: "OZYvDVHsfLebZw00En9vOO8Ta1pcIeuPO4Esbv2yCv4E",
            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzIyNjE4ODQxLCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6Ik9aWXZEVkhzZkxlYlp3MDBFbjl2T084VGExcGNJZXVQTzRFc2J2MnlDdjRFIn0.p4D33mKmiHZYiO4Zhihx48MNcJQu0orZkezy1Wubrr3rTMInJSSlBEqaqEKgfSo505qXHx9n-zabIuM4hbGmpVNPY2aX8L3jDZU-o076NuYCjpiB87eQd6ilimOw5U-n55uCeYDXO6WYENmsy3trq-8hBMTmdloNeFXnCx1aECETU4ZmXXo3GnZBkWEWpRHyVqhFFOYxkeEWWHMvgrGoqkZHvLhHC93H9maz3KKCrqFqJeFrEo_idoJ-AsBqYhTGKhO2uGV_fhGUda6Qetc9QrqEK0WuxHwqpRbjR1cyvTbWDwCcvES1gXx4UDiWs1wdpZuyC3j2Y4LuPGAiLVWatA",
            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzIyNjE4ODI4LCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6Ik9aWXZEVkhzZkxlYlp3MDBFbjl2T084VGExcGNJZXVQTzRFc2J2MnlDdjRFIn0.K6CCI-RGsTXGK0y-u2SseXea33tR5SbbX9wvucF7j0UictV6_VB0TsZe3SPlU_3ST0ecedLegbyJu-_4I6h7-XDApfXCGslYFoqM5iZnQ_5YtL0Zkdeh2iHJZKyS-mH_z6lyojggbFPLFGgRC0gZVfXJwdDtAUi33wOnlvkvGOdzNXmJCrRInkg7OfRKvLzxkQnQ0kTagKtq74Uv5JpG6XeascSi6tXExM8KVxG-4VEWHvBqCQvrpV6xlZmSnlOvoLT7E2oQB-6rwvy4cFnA_1ZASxHxiAZTNppPTmdmDYxDUd8qwJiL7MtF73sfqcrooH-z9p35u9t7eqiUGlslcA"
        )
    ]
}

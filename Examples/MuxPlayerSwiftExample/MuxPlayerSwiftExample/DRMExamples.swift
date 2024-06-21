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
            playbackID: "fPHwnrNKTqTdZTX00xmbbs316CauXMg02KJKZlpaxNKmc" ,
            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzI2MTYyMTMwLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.TDP-unjybwwTQJnSoYGwpNH-_lGM1-uhCdGIWYtS3XAyekSvhQYKQBiTMF435_31vIAVQ5H2rkyQvGA6CajZWgAWe_c9_ZuPB9CJ9SEvvGZmw8bj-k1H7vFzFA_dGhWIhnhi9eW1wl_w3EsxRwZP9BRrhLec8QZGN-JAvv-upPMFTXOo1O8DNg_pag9c0u0h609YwIcBcpvBrhZDAxied_xr7GpZuZaB7SY65gx0jSuYO4S1Wp5BgWJ3jSTRFSP2jPvNHxXr-VFoCKKnAZ5v9mV6pmRZ17A-U3IsL1tsRYkLC4toIrz24sdmaPIIj3-s1E2-5g3irRujtyxJTsUaTw",
            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzI2MTYyMTMzLCJraWQiOiJucFI2TFZHSjVMZG5pdXNzVzAwSEJHcHhzbElNVGVpSzhiaHI4Z0U2VHNtdyIsInN1YiI6ImZQSHduck5LVHFUZFpUWDAweG1iYnMzMTZDYXVYTWcwMktKS1pscGF4TkttYyJ9.OE06Sg79FagTAAho9fz-g0Jd6OexCrrey8j9v0ETo3UQ1wmawKPC95-3VJkT-qkvXgPaaApDmDS2c5ormiPZxAH3fO_nPDh8oVDGHQgnLXtKKCsL4j9jd2whBEoIpHYnjUnrp4pt1klJqGljN1LqUVYsecpXlh3JUPBjcoRW1eGuAdqbW4kfQpq7c-rZRLCs4WtFm8fSh8UamBLrvULJzgXGQmX1UlzIuN2Y_u-AxuO9VCKaSfLKobko2j9ozQ3VdnEqsThv3iQORCZHmuq4sxSwOyNLMidGcbiPGayJHDm31iG4mipdMzhICb22uCwZDEnEkT7TC08FSMMx1CZHWw"
        ),
//        DRMExample(
//            title: "Staging Test PlaybackID 2",
//            playbackID: "OZYvDVHsfLebZw00En9vOO8Ta1pcIeuPO4Esbv2yCv4E",
//            playbackToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ2IiwiZXhwIjoxNzIyNjE4ODQxLCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6Ik9aWXZEVkhzZkxlYlp3MDBFbjl2T084VGExcGNJZXVQTzRFc2J2MnlDdjRFIn0.p4D33mKmiHZYiO4Zhihx48MNcJQu0orZkezy1Wubrr3rTMInJSSlBEqaqEKgfSo505qXHx9n-zabIuM4hbGmpVNPY2aX8L3jDZU-o076NuYCjpiB87eQd6ilimOw5U-n55uCeYDXO6WYENmsy3trq-8hBMTmdloNeFXnCx1aECETU4ZmXXo3GnZBkWEWpRHyVqhFFOYxkeEWWHMvgrGoqkZHvLhHC93H9maz3KKCrqFqJeFrEo_idoJ-AsBqYhTGKhO2uGV_fhGUda6Qetc9QrqEK0WuxHwqpRbjR1cyvTbWDwCcvES1gXx4UDiWs1wdpZuyC3j2Y4LuPGAiLVWatA",
//            drmToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJsIiwiZXhwIjoxNzIyNjE4ODI4LCJraWQiOiJFelE2SkI1ZkQwMmd5TmVxUmE4MDJYT2xnMDE0SzAxckxwdXNDbklRSjJobEtYbyIsInN1YiI6Ik9aWXZEVkhzZkxlYlp3MDBFbjl2T084VGExcGNJZXVQTzRFc2J2MnlDdjRFIn0.K6CCI-RGsTXGK0y-u2SseXea33tR5SbbX9wvucF7j0UictV6_VB0TsZe3SPlU_3ST0ecedLegbyJu-_4I6h7-XDApfXCGslYFoqM5iZnQ_5YtL0Zkdeh2iHJZKyS-mH_z6lyojggbFPLFGgRC0gZVfXJwdDtAUi33wOnlvkvGOdzNXmJCrRInkg7OfRKvLzxkQnQ0kTagKtq74Uv5JpG6XeascSi6tXExM8KVxG-4VEWHvBqCQvrpV6xlZmSnlOvoLT7E2oQB-6rwvy4cFnA_1ZASxHxiAZTNppPTmdmDYxDUd8qwJiL7MtF73sfqcrooH-z9p35u9t7eqiUGlslcA"
//        )
    ]
}

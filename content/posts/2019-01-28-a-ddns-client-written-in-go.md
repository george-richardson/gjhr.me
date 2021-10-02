---
title:  "A ddns client written in go"
date:   2019-02-02 10:00:00 +0000
---

I have wanted to host something at home on my media PC for quite a while, but I've always been put off by buying yet another year-long subscription for a dynamic DNS provider that I will inevitably forget about until something breaks. However, last week I had an epiphany: AWS Route 53 is basically DDNS. As someone with AWS certification who uses Route53 pretty much every day, this is more than a little embarrassing.

After the blood had left my face I decided to do something about it. As this was going to be a long-running process which I would potentially want to run on multiple machines and operating systems I wanted to keep the executable small and portable. My go-to language is C# running on .Net Core but packaging up the runtime and NuGet package DLLs does not make for a small binary, so I had to look further afield. I frequently use a few programs that come as a single compact binary; notably, terraform. I have also noticed that these programs are more often than not written in go these days. Having encountered a few bugs in terraform that I could have probably fixed had I knew how to read/write go I figured it was high time to learn golang. 

My overall experience with go has been... frustrating. There are many aspects to the language which are less than ideal, these have all been well litigated on the go issues tracker and on the internet at large: 
 * [Error handling sucks](https://www.reddit.com/r/golang/comments/6v07ij/copypasting_if_err_nil_return_err_everywhere/).
 * [Generics don't exist](https://docs.google.com/document/d/1vrAy9gMpMoS3uaVphB32uVXX4pi-HnNjkMEgyAHX4N4/edit#heading=h.vuko0u3txoew). I knew about this going in but was almost immediately caught out by it.
 * [Package management is weird](https://github.com/golang/go/wiki/PackageManagementTools) (but [improving](https://github.com/golang/go/wiki/Modules)).

However having said that there are some lovely features in go, some of which I, unfortunately, didn't get to use too much of in this project:
 * Goroutines seem great.
 * Channels look amazing.
 * Compilation is a breeze, even cross compiling is simple. 
 * Strong standard library.
 * Very strong community packages, (In particular, [cobra](https://github.com/spf13/cobra) and [viper](https://github.com/spf13/viper) were useful). However, discoverability is limited by the fractured package management tooling.

Despite the learning curve and some moments where I wanted to end it all with an `if err != nil { panic() }` after a few hours I had a working program in [route-ddns](https://github.com/george-richardson/route-ddns). I no doubt have made many structural errors in this code but it works for my purposes and served as a nice introduction into the world of go. Try it out and open a PR if you want. I need to add more configuration options but its basic needed function is there.

Now to read [The Go Programming Language](https://www.goodreads.com/book/show/25080953-the-go-programming-language) and see if I can work out why some people are so evangelical about this language...
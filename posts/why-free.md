<!--
.. title: Why I'm making my app free
.. slug: why-free
.. date: 2022-04-24 06:27:21 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
-->

I'm an Indie Hacker and I've decided to make my app free. Sounds like a terrible decision, right?

I'm making a [browser extension](https://zimu.ai) that provides smart subtitles for Chinese videos, partly provided by my OCR subtitle extraction tool. I'm not doing it for the money, for that there's always the risk free alternative of regular employment. Then is it to become rich? Clearly not, then I'd definitely not target the fairly saturated niche of language learning. Besides, a one-man project is unlikely to generate that kind of revenue, that is left for the VC funded startups of the world. Why a one-man project then? It's mainly that at this point in our life with small kids, we want as much freedom as possible. That includes deciding when and where to work. Involving other people means meetings, oh so many meetings, specific work hours, less creative freedom and many a large pressure to turn a profit.

What I really want is to create as much value as possible while covering our expenses as a family. So the calculus is simple: maximize the "value" I can provide to other people, i.e. "number of users" times "value provided per user", subject to the constraint of paying most of our bills at some point in the future.

My conclusion after thinking about it for a long time is that the "normal" path of building an app with subscription or premium features is not what I want to do. It would probably be the fastest way to meet the constraint of covering our expenses, but it would severly impact how much value I could create. People are getting more comfortable paying for software nowadays, but it is still a very tiny minority who are willing to do that. Freemium with some features hidden behind a paywall is one way to go, but it creates this tension where you need to inconvenience people just enough so that enough people pay up. I don't like that dynamic, and usually it means hiding some very valuable features behind paywalls.

So here's my simple plan: make anything that _can_ be provided for free, free (some things may not, like anything that requires a back-end server to run). Then try to make some money at the margins like this:

1. Patreon: give some perks to patrons like the ability to vote on features, request specific TV shows to import, and even get the binary to run OCR themselves
2. VPN ads: I suspect people learning Chinese (either foreigners or heritage learners) have a greater than average need for a VPN, both for traveling to China, but also to access Chinese services from abroad. VPN companies also happen to pay out great commissions.
3. OCR as a service: Perhaps there is some small market for providing OCR on video subtitles as a service. At some point I'll create a separate landing page and buy some keywords to try this out.

This strategy is quite freeing from a technological and UX perspective. When building a subscription service on the web, it's almost a requirement to put most of your code on the server, so as to protect against piracy and hacking. This often makes sense when there are significant need for centralized coordination between user accounts, like social features, or there is a need for heavy processing that can't be done client-side.

My feeling though is that in many cases it's purely a user hostile choice, as a way to silo the data and protect against compentition. Making the app free simultaneously incentivices me to make it cheap to host, with a close to zero marginal cost per new user. This also happens to be in the user's best interest, as it means the app is less likely to disappear as it's not highly dependent on a server to run, and the user has complete control over their client-side data! There may be social features incorporated at some point, and there will be a need for some kind of back-end for syncing data between clients, but with a very limited server-side functionality this should not be too expensive to run.

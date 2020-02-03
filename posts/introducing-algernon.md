.. title: Introducing Algernon
.. slug: introducing-algernon
.. date: 2019-12-19 13:06:58 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text

## What is it?
Algernon is an open data, open source web-based tool for learning and remembering things, a companion you can count on to help with continuous learning throughout your life and career.

## Why (what's the problem?)
The online educational landscape right now consists of a bunch of walled gardens, disconnected learning resources and various flashcard tools.
Algernon sits somewhere between open source flashcard tools like Anki and walled gardens such as Coursera, Duolingo and Memrise, while leveraging other resources that are out there.

### The downsides of Walled Gardens
The upside of walled gardens is the curated content, but downsides are

1. Your data is not portable: you cannot take your data with you, so there is no way to integrate what you have learned through various services
2. The expectation that the service is the be all end all of its particular domain. When the service is out of content, there is usually no way for you to add your own or continue your study.
3. If the service would go down or change significantly, there is nothing you can do about it. This is a problem if you're learning for the long term, i.e. 10+ years.

### The downsides of Flashcard apps
There are many apps and services for studying and making flashcards. Some are offline apps such as Anki, Mnemosyne, SuperMemo, but there are also many web-based such as Quizlet.

The first downside of these tools is the fact that they're based on the concept of flashcards and decks, which I think is inherently limiting. While I personally use Anki and I like it very much, the fact that there are no connections between cards is a daily annoyance to me, especially for language learning. The problem is that different cards _intefere_ with each other in the spaced-repetition scheduling. For example, I have a mix of word and sentence translation cards, and it often happens that I get a sentence translation card, and then right after I get the word translation card for one of the words in that sentence. At that point I'm already primed to know the answer, but that doesn't mean I would have been able to answer it if it hadn't been for that sentence showing up right before. This messes up the _model_ of my memory of that word. That is just one example, but there are tons of reasons why one card can affect another.

The second downside which is related to the first one, is that there is no source of truth in all the unstructured data of flashcards and decks. In Anki, I can download shared decks made by other people, but there is no way to remove duplicate cards unless they are exactly identical. And the fact that everyone makes their own underlying note structure that generates the cards means there is no standard way to talk about a piece of knowledge.

### Other resources
On the other end, there are a _ton_ of free (and paid) resources for learning stuff on the web, things like blogs, wikis, open data sets and Youtube videos just to mention a few. If you want to study these in an effective way, you have to do a lot of manual work to get them into your SRS app, or set up your own manual system of study.

# How: on a high level
The two main parts of Algernon are the Knowledge Base and the Memory Model.

## Knowledge Base
The knowledge base represents the single source of truth, a carefully structured database for various hand-picked domains from which exercises are generated.
However, also allow unstructured data for those domains that are not yet incorporated.

The knowledge base will consist of

1. Sources with permissive licenses, such as open datasets and Creative Commons content.
2. Links to indexed web resources covered by copyrights. Just like a search engine that indexes based on keywords, we'll index based on concepts tied to the knowledge base.
3. If all goes well: Additions and edits by the community of users.

## Memory Model
Using the knowledge base and user responses to exercises generated from it, we build an integrated memory model that takes into account the interactions between items in the knowledge base.

Using the model, we make the knowledge base searchable based on difficulty, providing tailored recommendations for the specific user. Eventually, we can see what _kind_ of exercise would be most benefitial. For example, if I'm having trouble remembering a specific word, it might make sense to add more exercises with sentences containing that word rather than pounding on the word without the right context.

# How: on a technical level
Algernon will primarily be a web-based service, because making apps with a cross-platform codebase, dependencies and UIs is not something I have the skill or time for. Making it web-based also means that iterating and pushing out new versions will be much easier. I also envision this project using a lot of machine learning, which is most conveniently implemented in my go-to programming language: Python.

## Openness and freedom
I want this to be a tool you can depend on for a long time, which is why I think it's important that it's open source. Even if I can't provide free hosting, the user should always have the option of hosting it themselves. 

The openness goes for the data as well, not only the knowledge base (as far as it's legally possible to share), but also the user's personal memory model, which should be easy to export.

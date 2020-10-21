.. title: Algernon Work Log
.. slug: algernon-work-log
.. date: 2020-02-01 13:06:58 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
.. has_math: true

# 2020-06-13
I've been thinking about knowledge tracing and what it is we want to predict really. In the past I was thinking about it in terms of wanting to assign a probability for the person to correctly complete an exercise at a given point in time.  Ideally however, we actually the whole probability distribution of all possible answers, as a function of time. The probability for the _correct_ answer is just a special case of the having the full distribution. This would for example help with clearning up confusions or misunderstandings.

On another note, I want to add the grammar rules from the AllSet Learning Grammar wiki as separate items. I think most
of the rules can be hard-coded for segmentation, but it will be a lot of manual work.

# 2020-05-06
I'm thinking more and more that I need a browser extension eventually. One case where it would be extra useful is with Viki Rakuten videos, which cannot be embedded. With an extension we could either hook into the subtitles as they're being displayed (and allow adding them to vocab), or display them somewhere else and sync the time. It would also enable users to view sites which don't allow iframe embedding.

# 2020-05-03
Trying to build small classifiers for hanzi word -> pinyin. Before I relied mostly on the freqency in the ChinesePod transcripts, but I found a dataset called the The Lancaster Corpus of Mandarin Chinese which has hanzi as well as pinyin. Using this I can segement all the sentences and get examples of when a hanzi word is pronounced in different ways. With those examples I can train small decision tree on the POS tags generated from the Jieba segmentation.

Here's the dataset
https://ota.bodleian.ox.ac.uk/repository/xmlui/handle/20.500.12024/2474

But after parsing and analyzing the data, there doesn't seem to be enough ambiguous cases to build classifiers for them, instead I'll manually check the POS tags in a window and decide which reading it should be.

# 2020-04-25
I decided to pause the indexing parsing for now and focus on using sentence translations to pick words and word translations.

# 2020-04-23
I found another great podcasts site and I wanted to index the content, but the 24 posts had 4 different layouts, and some are really hard to parse without special code. So I think it's time I build an indexing module that has very few assumptions about the layout. The only thing we should need to know is what combination of hanzi, pinyin and translations there is on the page. My plan is this: 

1. Filter out HTML elements which we know contain hanzi or pinyin. Treat the rest as potential translations.
2. Use the Levenshtein code to align the three types of elements
    * Comparing hanzi and pinyin, use the Levenshtein distance using the same weighting function as I used for the chinesepod frequency database.
    * Comparing hanzi and translation, use the percentage of dictionary word translations that can be found in the translation
    * If all three are available, first work out the hanzi+pinyin to narrow down the word links, then cross reference with translation
3. Optionally provide selectors for where to look for content, if needed

The assumptions for this to work are:

1. Elements of a certain type (hanzi, pinyin or translation) are arranged sequentially on the page
2. Matching elements of different types are delimited in the same way. E.g. if one element has two hanzi sentences, the corresponding pinyin element is assumed to have two sentences.

# 2020-04-18
Instead of going for the strategy below, I opted for building a character-reading frequency database instead. I have some vague memory of seenig a character reading frequency database, but can't find it anymore.

What I decided to do was to use the ChinesePod transcripts, which have both hanzi, pinyin and translation, and simply get the pinyin reading frequencies from there. As it turns out though, there are frequent errors in the correspondence between the hanzi and the pinyin, but using the weighted Levenshtein distance I was able to align them and remove all errors (AFAIK).

Now that I've written the code for aligning them, I can use it in the sentence indexing as well, so that we can pick the correct word based on the hanzi and pinyin, if pinyin is available. Next up I'll also use the translation to disambiguate. I also want to point to specific translations within that word whenever possible. My plan is to do some simple heuristic, such as:

* For each candidate chinese word
    * For each word translation
        * Remove things within parenthesis and other "extra" information
        * Get the least frequent english word in the translation
        * If that english word exists in the sentence translation, then pick it.
    * If several translations had matches, keep links to all of them
* First go by pinyin if available, but then use translation as tie-breaker

# 2020-04-15
I've been having to manually correct the pinyin priority for many duo-yin-zi. The latest I found was 读 which got assigned dou4 rather than du2. Now that I've fixed so many of these, I think it's better to do some analysis and try to catch the unknown number of remaning errors. What I plan to do is: for each duo-yin-zi, find all compound words that contains the character, and order pronounciations by the frequency they appear in these words (and the frequency of those words).

There are however characters that have the same readings but different translations. In this case we still need a manual tie-breaker. It turns out thought that most of these cases in CEDICT, one instance contains of the other.


# 2020-04-14
I went ahead and implemented both optimizations mentioned yesterday. Might be a premature optimization, but I think it really helps that each search is 5ms instead of 40ms because I can see this being a bottleneck as people are typing in search queries or browsing around the tables. And the optimizations will work for any item type.

# 2020-04-13
There were lots of little issues with search match highlighting but I finally got it working, here's a screenshot:
[screenshot](/images/Screenshot_2020-04-13 Algernon.png)

While profiling the search queries I noticed that counting up the items takes like 90% of the time. It makes sense, since Postgres has to go through every single match to count them up. However, when actually fetching the matching items, it's usually much faster since we have e.g. LIMIT 25. This is true when fetching the first few pages, but as you go through the pages to the end with OFFSET, the time it takes to fetch them approaches the counting time. But now I see two optimizations that could be done:

1. Cache the number of items for a query, or just calculate it once by order of the front-end. This should then save 90-50% of the time for fetching different pages of that search query.
2. Wait to calculate the total number before the user requests a different page than the first one. This one might be tricky since we need to know the total number of pages to do pageination, but since I'm mainly using a slider for that, I could "hide" the fact that I don't know how many pages there are, until the user actually clicks somewhere else on that slider.

The combination of 1 and 2 means that we reduce the load for lots of unecessary queries (due to misspelling, spurious requests during typing etc), and then only do the count once when the user is looking through the results.

For non search queries I could also keep a record of the number of items in each table.

# 2020-04-10
I have an interesting problem aligning search matches in normalized pinyin, e.g "wo3 xi3huan", with the diacritical version "wǒ xǐhuan", since they are of differing length. Let's say the search term is "xi" and we find a match in the normalized pinyin, how do we get the range of the match in the diacritical version?

I was thinking this should be pretty easy, but then what if we search for "3 xi"? Then the 3 will match the tone of "wo", but we'll probably not want to highlight "wo" because of that. I'm thinking it might be better to keep the tonal numbers in the converted diacritical text, but just hide them on the front-end. Then all the indices are the same.

What I ended up doing is sending pinyiny with diacritical marks _and_ tonal numbers to the front-end, and then filtering out the tonal numbers there. That way the indices from the search lines up when I do the search match highlighting.

# 2020-04-04
I added text search on the fields in the items table using Django's contains/icontains filtering and full-text search. To speed it up I added Trigram GIN indexes.

I considered using full-text search for the translation field, but for this use case I realized it's a bad fit since we actually care about word ordering, we don't want stemming (since you might want to find uses of a specific word tense etc). However, a simple %LIKE% query also doesn't work well, since searching for "ok", will match "he looked left". I think first trying startswith=text, and then contains=f' {text}' will work well enough.


# 2020-02-28 - 2020-04-02
Well, things have been... interesting lately. I started working full time so I'll have less time to work on this, but I try to squeeze in some time here and there. And, well, Corona happened. I've been in self-imposed quarantine for the past 5 weeks, first at home and then at my parents house on the country-side. Getting any kind of work done with a 2-year-old around is challenging, even with babysitting help, but sometimes I get a few hours on the weekend, or on a rare day when I feel I've gotten enough done at my day job I'll allow myself to code a bit on this project. I've taken one big leap, and that is to move the UI away from Django templates+JQuery+Bootstrap to Vue.js Vuetify instead. The speed of developing an interactive is just orders of magnitue better with Vue.js, and I picked it over React and others because if I stick to modern browsers I don't even need a build system. The whole pile of complexity that is JS build systems, webpack, transpilers and NPM is something I want to avoid unless it's absolutely necessary.

Here's the result after porting one item list view to Vue.js:
[screenshot](/images/Screenshot_2020-04-02 Algernon.png)

Another benefit of using Vue.js and no build system is that it's perfect for enabling customization. Users can create an exercise component in a single file and upload it to be used in the application, and I can just include it directly. Naturally any user contributed code would have to go through review before others can see it.

For now I'm focusing on the sentence table and have a bunch of things to do:

* Separate the user review data to a separate end-point from the items. While this will require two API calls instead of one, it enables caching the items since they are the same for all users. In order to reduce load I can then only invalidate the cache at a set interval, even if there are changes to some items or added items. As the data solidifies over time it becomes less important to keep it completely up to date for the table/search. Of course, the more search options there are, the worse caching will work, but if we can cache the most common types, e.g. just plain search without any options maybe it will still help.
* Related to above, the user review end-point I think can return the whole data set, or the data that changed since time t, which we can keep consistent on the front-end. It's also not mission critical in case it's not consistent since it'll only be used for search. If a user has 10k reviewed items, and we send the first 64-bit bits instead of the full 256-bit UUID, then we could get away with 10k*(64+16) = 800 Kb, which is not too bad. 16-bit for the number of reviews.
* Implement text-search
* Filter by word-link
* Filter by source

# 2020-02-28
Thinking about what would be the optimal way to achieve "pinyin-guided" hanzi "word sense induction".

If the pinyin syllables perfectly match the hanzi characters, then it's easy: we just pick the word sense for each character that matches the pinyin.

But, we have many sentences where there are extra pinyin syllables such as, especially with numbers.
我副100块钱了 may have the pinyin wo3 fu4 yi1bai3 kuai4qian2 le. Maybe there are other cases. What I can do is to search through all the sentences in the database and print the ones with differing number of hanzi characters and pinyin syllables in order to get a sense of the problem.

Doing this, I saw that it's not only a problem for numbers, but there are often other errors.

The problem then is a bit of a chicken and egg problem: we need to generate the pinyin from the hanzi in order to do get the levenshtein ops. A brute force way of doing it would be to generate all possible combinations of pinyin from the hanzi and pick the one with the smallest levenshtein distance, but this would quickly become intractable. A faster method might be to first generate a greedy pinyin, where we just select the least difficult pinyin for each word, then do levenshtein matching on the two, then assume that the "replace" operations constitute the corrections. For this to work we need to encode pinyin syllables into a single unicode character.

# 2020-02-26

* Optimized the item page queries
* Fixed a bug where in rare cases the sentence links were not in order which caused
  sentences to have lots of extra text. Added an order by clause to fix it.
* Display a '-' for None values in the tables
* Fixed display difficulties when logged in vs anonymous. Use black for unknown words. Display explanation for the color codes.

Thinking about what would be most useful to include in a word popover. I'm thinking edit and queue buttons, but instead of just an "I know this" button, have 1 colored button for each level so the user can easily specify a level. Then we can put this level as a special review in the review log, which can then be used to calculate an up to date level after further reviews.

# 2020-02-23
Added checks in cedict for "(name)" and marking those words as having POS=nr, then filtering out those words when calculating sentence difficulty, and graying them out in the UI. Generally people are not interested studying/remembering person names, while cities, countries and other place names you generally do.

# 2020-02-22
Once again I'm questioning whether to use full-stack Django with JQuery, or a front-end framework like React, Vue or Svelte. The pros of the first approach is:

1. Can use Django forms for editing items, which come with automatic validation and easy tie-in to models
2. Already have auth in place, which is easy with Django
3. Don't have to engage much with the JS ecosystem and build systems.
4. Routing works better than SPA

The pros for using a front-end framework:
1. Get a reusable REST api for other apps
2. Sending less data over the wire (this is already a problem)
3. More modern/repsonsive UI
4. Exercise templates can be built as components in the framework

Possible compromise:
* Keep the auth end-points outside of the SPA
* Use an SPA everywhere else
* Use Bootstrap components with the SPA so we can intermingle SPA and Django

For now, due to lack of time, I'll stay on course with boring tech. Perfect is the enemy of good. An imperfect released project is infinitely better than a perfect project that is never done.

# 2020-02-21

### Database
Switching most on_delete=PROTECT to CASCADE, because I think that's what I really want, just wasn't sure how it all worked. It was getting messy having to delete dependencies in the right order.

I really need to clean up the prepare_text function. It has a few complications that make it complex:

1. We segment sentences with jieba.posseg.cut, but some of the words don't have matches in our dictionary, so we need to break it down further with jieba.tokenize(..., mode='search').
2. If the input is a dictionary word, we want to break it down futher if it contains multiple other dictionary words

Implemented choosing the link word based on the pinyin first, then tags, then the least difficult one.

I'm thinking it might be worth it to encode piyin syllables in binary, as unicode characters outside the ascii range. This would probably cut down on space by a factor of 4, and it could be useful for calculate string alignment between the pinyin supplied for a sentence and the pinyin from the hanzi.

# 2020-02-20
An interesting [quote](https://use-the-index-luke.com/sql/dml/insert):
> Nevertheless, the performance without indexes is so good that it can make sense to temporarily drop all indexes while loading large amounts of data—provided the indexes are not needed by any other SQL statements in the meantime. This can unleash a dramatic speed-up which is visible in the chart and is, in fact, a common practice in data warehouses.

So maybe it would make sense to drop some indexes from import_chinese_data and import_anki_collection.

### Optimization
So, I think I realized why loading the pages with a lot of words on it is slow, and why rendering is slow. It's because the generated HTML is 1.5 Mb! I guess all those spans with popover details really add up.


# 2020-02-19
After some more digging, it turns out that runnning an ORDER BY query on just the item table, with LIMIT and OFFSET takes only 10ms while just doing the join between the item and sentence table takes 70ms, and the ORDER BY another 70ms. So it seems like it would be better to not have the item fields in a separate table, but for each subclassed item table to duplicate the fields. Lesson learned: avoid joins! In that spirit I'll probably change the Source id to its name, which should be unique, and it's something that's useful to display in the UI.

The problem with getting rid of the items table is that Exercise refers to it with a foreign key. But we keep a item_table field there, because we still need to figure out which one to join with. So really it makes no difference if we remove the items table. When we do want to make a join between exercises and items, we'll just have to do it for one item table at a time.

Another upside, I can use bulk_create again without implementing my own! Interestingly enough, sorting by just difficulty now keeps the same internal order, so I don't have to sort by id.

# 2020-02-18
Shaved 33 seconds off importin my Anki collection by optimizing the previously implemented bulk_create. Instead of fetching all the sentences and then their words I instead fetch all the sentence words in one query.

### UI
Now displaying known/unkown sentence words if logged in using the stats in ZhUserWordSummary.
[screenshot](/images/Screenshot_2020-02-18 Algernon.png)

Surprisingly, the number of revs for a given word is much higher than I thought, probably due to them being in sentences. When setting the color it makes sense to set the limits for each level quite high, now 10, 25, 50, 100 revs respectively. These numbers seem to work for my Anki revs, but will have to make sure it generalizes.

Halfway implementing the word tooltip as a popover instead, with an "add to queue" and an "I know this" button shortcuts. Also refactoring the format_word to output both hanzi and pinyn in the same cell since iterating over all word links seems one reason the rendering is so slow.

### Database
Investigating again why item listing is so slow. Notices that listing sentences does a sort on disk in PostgresSQL. This is due to the table not fitting in working memory, which is set to 4 Mb. We can increase it by setting work_mem higher in PostgreSQL: `alter database algernon set work_mem='64MB';`. The downside is that each query might take this much memory... And it doesn't seem to speed up the query a whole lot, just ~20% (100ms -> 80ms).

Been trying very hard to profile what takes so long besides the SQL queries. Managed to find the profiling bar in Django Debug Toolbar, but the granularity is quite low. It seems like Django spends a ton of time iterating over and post-processing the result for the database queries. I cannot fathom why this takes any significant amount of time. I guess I'll have to solve this with caching.

# 2020-02-16
Implemented the populating of ZhUserWordSummary as a bulk_create Manager method instead of a signal, in order to allow bulk processing and speeding things up. It's still quite slow but better than the first implementation.


# 2020-02-15
Tried using PostgreSQL triggers to automatically populate a ZhUserWordSummary database from added reviews in the ReviewLog table, but decided to use django triggers instead because they're versioned more easily and require no database migrations, although they are slower since they need separate database queries. Another upside is being able to run ML model inference which will be hard in SQL.

# 2020-02-14

### Database
Trying to make import_chinese_data faster to speed up development. Tried caching the mp3 file metadata instead of reading it every time, but it seems like the biggest problem was actually calculating the levenshtein distance between transcript and transcribed. Might be worth converting it to Cython to speed it up, since this step now takes 8 minutes. On second thought, it probably most of its time in the supplied substitution_cost function. After profiling it seems not to be the case.

I tried optimizing the function with Cython, but not able to get any speedup, pausing this for now. Opt for just caching the resulting timings instead, because that algorithm rarely changes. This improved the time from 8 minutes to 2m22s.

# 2020-02-12

### Database
Found a case where the Jieba segmentation is wrong: 下週 is split in to 下 and 週, while the compound is in the dictionary. I might have to go back to overriding the segmentation if there exists words in the dictionary that encompass several of the segments. I remember cases where this didn't work though, so might have to add a white list instead.
Another case: 暱称 - nickname

### UI
Finished level highlighting for words, both in hanzi and pinyin.

Working on displaying the user knowledge level for each word instead of difficulty level. Will need to make a crazy expensive join that we'll obviously have to cache somehow.


# 2020-02-11

### UI
Working on a way to visualize the difficulty of a (external) media item, both for anonymous and logged in users. Considering a histogram over HSK levels. The problem with that is that lvl just by virtue of Zipf's law the earlier levels will always contain most of the vocabulary. But maybe it's worth a try, just to see if it's useful. For logged in users the histogram would instead be over levels of user knowledge.

Converted "normalized" pinyin with numbers to diacriticals for the UI.

Added per-word color highlighting for the hanzi field in sentences list. This surfaced quite a number of problems with the HSK level / difficulty level of words:

1. We probably want to sort out pronouns like names (probably not countries/cities though), since they are rare in the corpus and affect the difficulty of the sentence.
2. If there is no frequency for a word, we currently use the minimum frequency of the linked words. However, in many cases there are no such linked words, since they may not be in the dictionary. In those cases we probably want to assign a frequency for those words based on the compound words it appears in.

### Database
There are pure dialogues, short stories and other readings on ilovelearningchinese.com that I should index. Need a new model for reading material.

I added has_dialogue and has_lesson fields to Media and ExternalMedia so that we can filter on those in the future, for when you want just dialouge without tons of explanation.


# 2020-02-09

Adding a file hash field to the item model, and renaming source_pointer to source_file_id. For now I'm using the first 64 bits of the md5 hash and store them as integer fields. With those two fields will help with updating items when the source material updates, or we've updated the algorithms, but can't regenerate the database from a clean slate.

# 2020-02-08

### UI
Implemented ability to combine two or more fields into one switchable column. This is conventient for combining hanzi and pinyin. The preference is saved in a cookie.

I noticed the sentences list view loading fairly slow and turned on the Django debug toolbar. I reduced the number of requests by prefetching/selecting links and source. But I noticed just getting the number of items in the table for pageination took 12ms!. It turns out Postgres doesn't keep a count metadata for tables, so a SELECT COUNT(*) FROM table_name; has to go through the whole table. Wow. There seems to be a way to get an approximate count, but it's only updated when running certain commands. The better solution instead seems to be using a Django signal to keep a count in a separate table.

# 2020-02-07

### Database
There is a problem with the  frequency data for homonyms. E.g the word 都 can be dou1 (both/all) which is very common, or du1 (capital) which is fairly common, but the frequency information I'm using from Jieba includes all homonyms of a word. This becomes a problem when I generate the word links for a sentence, as if there are multiple matches I pick the highest frequency one. So far I've been dealing with this problem by overriding the frequency, usually setting it to 0 for the less common homonym. The problem with this is that I now calculate the difficulty based on this frequency, so I have to be a bit more careful. Therefore, I'll try to override using a compound word, e.g for 重 zhong4/heavy, there is the less common chong2/repeat. But "repeat" is usually a two character word "重复", so we can take the frequency from that word instead of setting it to some arbitrary number. For other words, it might be better to set the frequency based on the HSK level it would end up in.

### UI
Abstracted the item table to be reusable for both item lists, and the list of links on the item view.

# 2020-02-06

### Database
I think I have to mark some external media as "lesson" which includes explanations, vs. "dialogue/story" which is just Chinese. Chinesepod audio already has this distinction.

Found some new sites worth indexing:
Lots of articles for reading and audio: https://www.chinesereadersguild.com
Reading practice: http://chinesereadingpractice.com
Picture books for children: http://mandarinforme.com

Added an index to the difficulty field.

# 2020-02-05

Gave all Chinese models a "Zh" prefix and renamed "mandarin" to "zh", just to have a shorter namespace.

Thinking about how to calculate difficulty for indexed websites where the word source is just a list of words rather than the whole transcript. The problem is that only the difficulty words are usually listed.

When I tried calculating the difficulty for ChinesePod podcasts, the interesting thing was that I can see on the titles, which include the difficulty level, whether the calculated difficulty sorts the podcasts in the same order. Turns out just sorting it based on audio duration, or the sum of all the sentence difficulties (which in turn are the sum of the word difficulties) worked best. Using the average sentence difficulty did not work very well. Will have to investigate further why this is. It could be that words are put in a higher level than they should be.

### Bugs
Fixed sources not working for external media.

Saw that many external media podcasts didn't have a duration. Seems like I filtered on file ending with .mp3, but some urls had a query string attached, so fixed this and rerun the indexing of all sites to make sure I get the duration.

### Database
Contemplating adding the media URL to the database for external media. While it should be legal to link to publically available resources on the web, I also don't want to hurt the businesses by reducing their ad revenue or exposure by the visit a user would have brought. One mitigation might be to require the user to visit the site before showing the link to the media.

# 2020-02-04

### Bugs
Fixed some bad word links which was partly due to a bug, and partly the wrong homonyms being picked due to missing frequency information. It is really easier finding these bugs now that I have some kind of visualization of the data.

### UI
Abstracted the ItemView, ItemListView and templates for both sentences and media. Combine the hanzi and pinyin fields to one switchable field since they take up so much space and you usually only need one.

# 2020-02-03

### Bulk insert speedup
Measured the speedup by using bulk insert for 110k words:

* Before: 558s
* After: 24s

For a speedup of 20x! Well worth doing I think. 

### Potential 7th HSK level
Looking at the stats for HSK levels, and whether to create a level 7:

* HSK level 1 mean: 59673 std: 131535
* HSK level 2 mean: 26994 std: 54312
* HSK level 3 mean: 12393 std: 21252
* HSK level 4 mean: 6872 std: 13899
* HSK level 5 mean: 3599 std: 4798
* HSK level 6 mean: 1294 std: 1918

Since level 6 covers 0 frequency within a single standard deviation, conclusion to me is that it's best not to make another level.

### Item rank for recommendations and discovery

Thinking about how we can rank items for recommendations / discovery. In a way the problem is similar to regular search engine rankings: the query is now the words in a user's vocabulary, and the documents are the items (i.e sentences, podcasts etc). The problem is that the crieria for ranking are very different. TF-IDF would make no sense, as we're not interested in specifically finding documents with the user's vocabulary in them, but documents whose out-of-vocab words are not too many, and not too difficult.

Another thing to look at would be collaborative filtering. You could see each item as a "thing" to be recommended, based on what similar users have added at a similar knowledge state. The problem is that once you have a new item, we won't know what to do with it.

I think the ideal solution would be to check how many out-of-vocab words and of what difficulty are in each item and rank based on that. The problem with this is this would be an O(number of items * number of users * average user vocab size) operation. With number of items number in the hundreds of thousans, and average user vocab in the hundreds or thousands, I don't think this is feasible unless you first filter down the possible items.

In order to filter down we could manually assign a difficulty value to each item (which is what I've done so far). I would however prefer to learn this mapping instead. We could reduce both the item difficulty and the user knowledge level to a single number that we can index and filter on. Let's say we use the histogram of dependent item difficulties in an item, and a histogram of user vocab item difficulties as the input, then we could learn a mapping to two float values. For this we'd need some actual data. Initially, I could use my own Anki history for this. With this history, I can see when I added a sentence and the knowledge level I had at that point in time. A simple thing to try would be to essientially do a single neuron layer without an activation for both histograms, and minimize the squared error between them:

$$L = \sum_{t,u} (w_t \cdot (h_t + b_t) - w_u \cdot (h_u + b_u))^2$$

where we project the item difficulty histogram $h_t$, translated by a bias $b_t$ to a single number using the weight vector $w_t$. Similarly for the user difficulty histogram. We can train this once and then fine-tune the user parameters $w_u, b_u$ as we go in order to provide a bit more personalized results, if e.g. the user tends to prefer easier or more difficult items.

The problem with my own dataset is that my proficiency level doesn't span very many levels, as I started using Anki after I'd done most of HSK3. Anyway, the solution that will be reached by the optimizer will be all zeroes for all parameters, which means all items and user states will be mapped to zero and there will be zero loss. To avoid that we can add a negative regularizer on the parameters, pushing them away from zero, but that would probably mean that both the item and user state will be mapped to some other non-zero value. A simple trick might be to add a negative regularizer of the standard deviation of the resulting scores as this would penalize narrow distributions:
$$v_t^i = w_t \cdot (h_t^i + b_t)$$
$$v_u^i = w_u \cdot (h_u^i + b_u)$$
$$L = \sum_{i \in D}[(v_t^i - v_u^i)^2] - \beta Var_{i \in D}(v_t^i) - \beta Var_{i \in D}(v_u^i)$$
where D is the dataset of pairs of histograms of items and user knowledge states.

Perhaps running each value through the logistic funcion, in a sense turning it into logistic regression,
might be a good way to keep the values within bounds [0-1].

### Bugs
I noticed "common knowledge" words/expressions like "happy birthday" has a very low frequency in the corpus. I might want to go through Chinesepod lessons and mark words with the level of the lesson, if the word previously has a high level due to being infrequent.

I also saw 还 being linked to huan2 instead of hai2, and some other examples like that I need to look into. Also 的->di1.

### UI
Started on a common ItemListView with template that simplifies creating a list view for each type of item.

### Screenshot
[screenshot](/images/Screenshot_2020-02-03 Algernon.png)

# 2020-02-02
Implemented the bulk insert of items. It was a bunch of work but should come in handy throughout the project. Still working on the link finding generalization. One problem with reusing the link finding for individual words is that the Jieba segmenter returns the full word, and we want to use the sub-words if they do exist.

Found one problem with the current "greedy" linker for words such as "试试看". Tokenizing with Jieba in search mode produces the full word, 试看 and 试试. The greedy matching will pick 试试 for the first two character slots, and then it won't be able to match anything else, since only 看 is left. To make this work we'd need to do another word lookup rather than using the tokens found by Jieba.

# 2020-02-01
Generalizing finding links between sentences->words and compound words -> words. Previously had separate logic for this which is unnecessary. Generally, the procedure is to segment the text with Jieba, and linking with database Words, disambiguated with the pinyin and translation if supplied.

Would like to speed up the inserting of words into the database, since there are 110k of them it's very slow. But since Django doesn't support bulk_create for linked tables, there's not much we can do, unless we write the query manually. Maybe it's worth optimizing because I have to rerun `import_chinese_data` everytime I update the code.

# 2020-01-31
Working on setting a difficulty level for all the items in the database. At first my idea was to set the word difficulty based on frequency, but normalizing the range of frequencies gets rather complicated. For now I'll use the HSK level if set/known, otherwise I'll determine a "pseudo" HSK level based on which level the word frequency matches best. So for all HSK levels, I fetch all the words for that level and calculate mean and standard deviation of their frequencies, estimating the parameters of their normal distribution. I then go through each word without an HSK level, but with a frequency, and pick the maximum likelihood distribution. In the future maybe it's best to add a level 7, where we can put words that are very rare.

# No more logs
Unfortunately I didn't start logging my work from the start, but as they say, the best time to plant a tree was 10 years ago, the next best is today.

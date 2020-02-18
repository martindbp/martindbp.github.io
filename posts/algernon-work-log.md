.. title: Algernon Work Log
.. slug: algernon-work-log
.. date: 2020-02-01 13:06:58 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
.. has_math: true

# 2020-02-18
Shaved 33 seconds off importin my Anki collection by optimizing the previously implemented bulk_create. Instead of fetching all the sentences and then their words I instead fetch all the sentence words in one query.

### UI
Now displaying known/unkown sentence words if logged in using the stats in ZhUserWordSummary.

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

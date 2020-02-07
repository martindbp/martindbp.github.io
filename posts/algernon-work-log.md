.. title: Algernon Work Log
.. slug: algernon-work-log
.. date: 2020-02-01 13:06:58 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
.. has_math: true

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

Thinking about how to calculate difficulty for crawled websites where the word source is just a list of words rather than the whole transcript. The problem is that only the difficulty words are usually listed.

When I tried calculating the difficulty for ChinesePod podcasts, the interesting thing was that I can see on the titles, which include the difficulty level, whether the calculated difficulty sorts the podcasts in the same order. Turns out just sorting it based on audio duration, or the sum of all the sentence difficulties (which in turn are the sum of the word difficulties) worked best. Using the average sentence difficulty did not work very well. Will have to investigate further why this is. It could be that words are put in a higher level than they should be.

### Bugs
Fixed sources not working for external media.

Saw that many external media podcasts didn't have a duration. Seems like I filtered on file ending with .mp3, but some urls had a query string attached, so fixed this and rerun the crawling of all sites to make sure I get the duration.

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

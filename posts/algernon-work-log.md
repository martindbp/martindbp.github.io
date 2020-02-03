.. title: Algernon Work Log
.. slug: algernon-work-log
.. date: 2020-02-01 13:06:58 UTC
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
.. has_math: true

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

$L = \sum_{t,u} (w_t \cdot (h_t + b_t) - w_u \cdot (h_u + b_u))^2$

where we project the item difficulty histogram $h_t$, translated by a bias $b_t$ to a single number using the weight vector $w_t$. Similarly for the user difficulty histogram. We can train this once and then fine-tune the user parameters $w_u, b_u$ as we go in order to provide a bit more personalized results, if e.g. the user tends to prefer easier or more difficult items.

The problem with my own dataset is that my proficiency level doesn't span very many levels, as I started using Anki after I'd done most of HSK3. Anyway, the solution that will be reached by the optimizer will be all zeroes for all parameters, which means all items and user states will be mapped to zero and there will be zero loss. To avoid that we can add a negative regularizer on the parameters, pushing them away from zero, but that would probably mean that both the item and user state will be mapped to some other non-zero value. A simple trick might be to add a negative regularizer of the standard deviation of the resulting scores as this would penalize narrow distributions:
$$v_t^i = w_t \cdot (h_t^i + b_t)$$
$$v_u^i = w_u \cdot (h_u^i + b_u)$$
$$L = \sum_{i \in D}[(v_t^i - v_u^i)^2] - \beta Var_{i \in D}(v_t^i) - \beta Var_{i \in D}(v_u^i)$$
where D is the dataset of pairs of histograms of items and user knowledge states.

### Bugs
I noticed "common knowledge" words/expressions like "happy birthday" has a very low frequency in the corpus. I might want to go through Chinesepod lessons and mark words with the level of the lesson, if the word previously has a high level due to being infrequent.

I also saw 还 being linked to huan2 instead of hai2, and some other examples like that I need to look into. Also 的->di1.

### UI
Started on a common ItemListView with template that simplifies creating a list view for each type of item.

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

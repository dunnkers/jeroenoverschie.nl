> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# pyspark-bucketmap
- URL: https://jeroenoverschie.nl/pyspark-bucketmap/
- Published: 2022-10-22T10:01:09.000Z
- Updated: 2026-09-08T08:04:55.000Z
- Description: pyspark-bucketmap is a tiny module for pyspark which allows you to bucketize DataFrame rows and map their values easily.
- Author: Jeroen Overschie
- Tags: Code snippets

Have you ever heard of pyspark's [Bucketizer](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.ml.feature.Bucketizer.html)? It can be really useful! Although you perhaps won't need it for some simple transformation, it can be really useful for certain usecases.

In this blogpost, we will:

1. Explore the `Bucketizer` class
2. Combine it with `create_map`
3. Use a module so we don't have to write the logic ourselves 🗝🥳

Let's get started!

## The problem

First, let's boot up a local spark session:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()
spark

```

Say we have this dataset containing some persons:

```python
from pyspark.sql import Row

people = spark.createDataFrame(
    [
        Row(age=12, name="Damian"),
        Row(age=15, name="Jake"),
        Row(age=18, name="Dominic"),
        Row(age=20, name="John"),
        Row(age=27, name="Jerry"),
        Row(age=101, name="Jerry's Grandpa"),
    ]
)
people

```

Okay, that's great. Now, what we would like to do, is map each person's age to an age category.

| age range     | life phase      |
| ------------- | --------------- |
| 0 to 12       | Child           |
| 12 to 18      | Teenager        |
| 18 to 25      | Young adulthood |
| 25 to 70      | Adult           |
| 70 and beyond | Elderly         |

How best to go about this?

## Using `Bucketizer` \+ `create_map`

We can use pyspark's `Bucketizer` for this. It works like so:

```python
from pyspark.ml.feature import Bucketizer
from pyspark.sql import DataFrame

bucketizer = Bucketizer(
    inputCol="age",
    outputCol="life phase",
    splits=[
        -float("inf"), 0, 12, 18, 25, 70, float("inf")
    ]
)
bucketed: DataFrame = bucketizer.transform(people)
bucketed.show()

```

| age | name            | life phase |
| --- | --------------- | ---------- |
| 12  | Damian          | 2.0        |
| 15  | Jake            | 2.0        |
| 18  | Dominic         | 3.0        |
| 20  | John            | 3.0        |
| 27  | Jerry           | 4.0        |
| 101 | Jerry's Grandpa | 5.0        |

Cool! We just put our ages in buckets, represented by numbers. Let's now map each bucket to a life phase.

```python
from pyspark.sql.functions import lit, create_map
from typing import Dict
from pyspark.sql.column import Column

range_mapper = create_map(
    [lit(0.0), lit("Not yet born")]
    + [lit(1.0), lit("Child")]
    + [lit(2.0), lit("Teenager")]
    + [lit(3.0), lit("Young adulthood")]
    + [lit(4.0), lit("Adult")]
    + [lit(5.0), lit("Elderly")]
)
people_phase_column: Column = bucketed["life phase"]
people_with_phase: DataFrame = bucketed.withColumn(
    "life phase", range_mapper[people_phase_column]
)
people_with_phase.show()

```

| age | name            | life phase      |
| --- | --------------- | --------------- |
| 12  | Damian          | Teenager        |
| 15  | Jake            | Teenager        |
| 18  | Dominic         | Young adulthood |
| 20  | John            | Young adulthood |
| 27  | Jerry           | Adult           |
| 101 | Jerry's Grandpa | Elderly         |

🎉 Success!

Using a combination of `Bucketizer` and `create_map`, we managed to map people's age to their life phases.

## `pyspark-bucketmap`

🎁 As a bonus, I put all of the above in a neat little module, which you can install simply using `pip`.

```python
%pip install pyspark-bucketmap

```

Define the splits and mappings like before. Each dictionary key is a mapping to the n-th bucket (for example, bucket 1 refers to the range `0` to `12`).

```python
from typing import List

splits: List[float] = [-float("inf"), 0, 12, 18, 25, 70, float("inf")]
mapping: Dict[int, Column] = {
    0: lit("Not yet born"),
    1: lit("Child"),
    2: lit("Teenager"),
    3: lit("Young adulthood"),
    4: lit("Adult"),
    5: lit("Elderly"),
}

```

Then, simply import `pyspark_bucketmap.BucketMap` and call `transform()`.

```python
from pyspark_bucketmap import BucketMap
from typing import List, Dict

bucket_mapper = BucketMap(
    splits=splits, mapping=mapping, inputCol="age", outputCol="phase"
)
phases_actual: DataFrame = bucket_mapper.transform(people).select("name", "phase")
phases_actual.show()

```

| name            | phase           |
| --------------- | --------------- |
| Damian          | Teenager        |
| Jake            | Teenager        |
| Dominic         | Young adulthood |
| John            | Young adulthood |
| Jerry           | Adult           |
| Jerry's Grandpa | Elderly         |

Cheers 🙏🏻

You can find the module here:  
<https://github.com/dunnkers/pyspark-bucketmap>

---

Written by [Jeroen Overschie](https://jeroenoverschie.nl/), working at [GoDataDriven](https://godatadriven.com/).
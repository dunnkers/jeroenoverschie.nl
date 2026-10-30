> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# Musical Key Recognition using a Hidden Markov Model
- URL: https://jeroenoverschie.nl/musical-key-recognition-using-a-hidden-markov-model/
- Published: 2021-02-11T23:00:00.000Z
- Updated: 2026-10-30T16:19:38.000Z
- Description: Every musical piece has a distinct key. In this project, a Hidden Markov Model is trained to try and predict such a key.
- Author: Jeroen Overschie
- Tags: AI & ML

Underlying every musical piece is its [key](https://en.wikipedia.org/wiki/Key%5F%28music%29). It determines the group of sound pitches that are used, and tells really a lot about its sound. Among others, it's useful for DJ's, who can benefit from selecting tracks that have similar key, so the sound matches nicely. Now, in this project, we took on the challenge of trying to train a model to predict such a key. Let's see how we did this.

## Intuition

First of all, we must know there are 24 keys, 12 in major and 12 in minor. They can be illustrated like so:

![](https://jeroenoverschie.nl/content/images/2021/11/Circle_of_5ths-1024x1020-1.png)

Musical keys illustrated in a circle diagram. Courtesy of [Tad Dreis](http://www.wildflowerharmonica.com/4ths/).

Now, we chose Hidden Markov Models (HMMs) as our main instrument to try to predict the correct musical key, given a set of [*Chroma vectors*](https://en.wikipedia.org/wiki/Chroma%5Ffeature). Such vectors represent the relative strength of each pitch in different segments of the track, which data we have for about 10,000 tracks. We obtain such Chroma vectors using Spotify's web API, which additionally gives us a ground-truth indication of the actual music key, such that we can use supervised learning to train our HMM. 

The key insight is to train an HMM for both major and minor, separately. Then, we create copies of those models and retrain them with a circular shift in its key. In this way, we train a model for every key: such, we can predict the probability of a song belonging to a certain key, by searching for the model assigning the highest probability to its output. The process can be illustrated as follows:

![](https://jeroenoverschie.nl/content/images/2021/11/music-key-classification-1.png)

Illustration of training an HMM using Chroma vectors. Courtesy of Peeters G (2006).

## Execution

The actual implementation of the code and project can be found on GitHub:

![](https://jeroenoverschie.nl/content/images/2021/11/github32-2.png)

[music-key-classification](https://github.com/dunnkers/music-key-classification)
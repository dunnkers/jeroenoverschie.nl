> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# Making Art with Generative Adversarial Networks
- URL: https://jeroenoverschie.nl/making-art-with-generative-adversarial-networks/
- Published: 2021-04-08T22:00:00.000Z
- Updated: 2021-11-28T21:28:08.000Z
- Description: Can computers make art? To find out, we tried ourselves. We used Generative Adversarial Networks to try to paint new Van Gogh paintings.
- Author: Jeroen Overschie
- Tags: Data Science

Generative Adversarial Networks ([GAN's](https://arxiv.org/abs/1406.2661)) are a relatively new type of technique for generating samples from a learned distribution, in which two networks are simultaneously trained whilst competing against each other. Applications for GAN’s are numerous, including image up-sampling, image generation, and the recently quite popular **Deep Fakes**. In this project, we aim to train such a Generative Adversarial Network ourselves, with the purpose of image generation, specifically. As the generation of human faces has been widely studied, we have chosen a different topic, namely: the generation of paintings. While large datasets of paintings are available, we have opted to restrict ourselves to one artist, as we believe this will give a better chance at producing realistic paintings. For this, we have chosen the Dutch artist *Vincent van Gogh*, who is known for his unique style.

## How

There are many GAN architectures around. Some popular of which the [DCGAN](https://arxiv.org/abs/1511.06434) and the [StyleGAN](https://arxiv.org/abs/1812.04948). We decided to train both and compare the results.

- DCGAN. A GAN architecture that has been around for a while. Was trained using [TensorFlow](https://www.tensorflow.org/).
- StyleGAN. A popular GAN architecture for generating faces, provisioned by NVIDIA Research. Also trained using TensorFlow.

Both were trained on the [Van Gogh dataset](https://www.kaggle.com/ipythonx/van-gogh-paintings), as available on Kaggle. Because the dataset contained only a limited amount of paintings (painting is, of course, a very time consuming activity), we decided to augment the dataset. Among others, we applied rotation- and shearing operations, and modified the brightness, such that we get more training data.

The StyleGAN showed the most promising results. Starting out with a seed previously used to generate a face, we managed to train a GAN that produced something that remotely resembled art. Given that a computer is doing this, that's pretty neat!

![](https://jeroenoverschie.nl/content/images/2021/11/retrain_morphing.png)

Progressively grown StyleGAN. The adversarial network first takes on the task of creating low-resolution art, and then progressively makes sharper images (fakes).

## More reading

To read a more detailed report on this project, check out the Github page:

[![](https://jeroenoverschie.nl/content/images/2021/11/github32-2.png)](https://github.com/dunnkers/generative-adversarial-networks)

[generative-adversarial-networks](https://github.com/dunnkers/generative-adversarial-networks)
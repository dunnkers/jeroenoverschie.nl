> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# Finding 'God' components in Apache Tika
- URL: https://jeroenoverschie.nl/finding-god-components-in-apache-tika/
- Published: 2021-01-16T23:00:00.000Z
- Updated: 2021-11-28T20:19:15.000Z
- Author: Jeroen Overschie
- Tags: Software Engineering

How did big, bulky software components come into being? In this project, we explore the evolution of so-called *[God Components](https://en.wikipedia.org/wiki/God%5Fobject)*; pieces of software with a large number of classes or lines of code that got very large over time. Our analysis was run on the [Apache Tika](https://tika.apache.org/) codebase.

![](https://jeroenoverschie.nl/content/images/2021/11/tika.png)

Apache Tika is a software package for extracting metadata and text from many file extensions.

In this project, we set the following **goals**:

- Search through the Java code programmatically and find components that exceed a certain size threshold
- Find out how those components evolved over time. Did certain developers often contribute to creating God components - in other words - code that is hard to maintain?

To find out, we took roughly the following **steps**:

1. Using a Python script, we created an index of the Tika codebase at every point in time. That is, we created a list of every Commit ID in the project.
2. For every commit, we run [Designite](https://www.designite-tools.com/) \- which is a tool to find architectural smells in Java projects. Because so many versions of the codebase had to be analyzed, this stage of the analysis was done on the University's supercomputer, [Peregrine](https://www.rug.nl/society-business/centre-for-information-technology/research/services/hpc/facilities/peregrine-hpc-cluster?lang=en).
3. Using a Jupyter Notebook, we aggregate and summarize all information outputted by Designite. The amount of data to parse was large, so it was important to map-reduce as quickly as possible without losing critical information.

Such, we were able to visualize exactly at which time a component has been a God Component in the Tika codebase:

![](https://jeroenoverschie.nl/content/images/2021/11/gc-lineplot.png)

Chart indicating when components started- and stopped being a 'God Component'.

For more results, check out the complete Jupyter Notebook:

[God Components in Apache TikaHow do God Components evolve in Apache Tika? A qualitative and quantitative analysis.Jeroen Overschie](https://dunnkers.com/god-components/)

A Jupyter Notebook showing the final results of the analysis.

### Further reading

For more information, check out the Github page:

![](https://jeroenoverschie.nl/content/images/2021/11/github32-2.png)

[god-components](https://github.com/dunnkers/god-components/)
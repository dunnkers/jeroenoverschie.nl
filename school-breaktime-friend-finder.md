> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# School break time friend finder
- URL: https://jeroenoverschie.nl/school-breaktime-friend-finder/
- Published: 2015-02-20T14:00:00.000Z
- Updated: 2022-01-06T13:09:24.000Z
- Description: Spending school breaks alone is lame. That's why I developed an app so students can find with whom they share their breaks.
- Author: Jeroen Overschie
- Tags: Software Engineering

At my school, students often had gaps in their schedules. In between lessons scheduled for the day, one would often have breaks in between. But because you chose a personalized package of classes to follow, everyone's schedule was also different. So, it would be hard to know with whom you could spend those breaks! To solve this, I developed this app. It allows students to find with whom they have breaks so they can hang out with them whilst waiting for the next class 😊. The app was actually used by students in my school. Very cool! 

### Building the app

The entire app is quite sophisticated. The various components can be laid out as follows:

- Node.js backend ([Github](https://github.com/dunnkers/roosters-api))  
\- Has three main responsibilities:  
(1) to scrape student schedules off HTML pages into a MongoDB database. Scraping is done using [Cheerio](https://cheerio.js.org/) and communication with MongoDB via [MongoJS](https://github.com/mongo-js/mongojs).  
(2) parse the schedules into a relational format and compute what odd break-time hours exist.  
(3) expose the MongoDB database as an API.
- Ember.js frontend ([Github](https://github.com/dunnkers/roosters))  
\- This front-end then consumes the API data using ember-data. I'm using Bootstrap as a UI framework so I don't have to build all the buttons, tables and interfacing myself.

![An overview of the app architecture. A Node.js app scrapes and parses student schedules, puts it in a database, which an Ember.js app then consumes through a REST API.](https://jeroenoverschie.nl/content/images/2022/01/PWS-roosters-infrastructuur.svg) 

An overview of the app architecture. A Node.js app scrapes and parses student schedules, puts it in a database, which an Ember.js app then consumes through a REST API.

... the relational mapping in the database is as follows:

![An Object-Relational-Mapping (ORM) of the school. Most important is a lesson, which then relates teachers, students and a room.](https://jeroenoverschie.nl/content/images/2022/01/PWS-Roosters-ORM---Object-Relational-Mapping.svg) 

An Object-Relational-Mapping (ORM) of the school. Most important is a lesson, which then relates teachers, students and a room.

And our working app looks as follows:

![](https://jeroenoverschie.nl/content/images/2022/01/Screen-Shot-2022-01-06-at-13.53.37.png)

The working break-time friend finder app. Using a simple search, a student can find his schedule.

But most importantly, the functionality to see whoever shares your break-time ('tussen' in the picture below) or any classes with you:

![](https://jeroenoverschie.nl/content/images/2022/01/Screen-Shot-2022-01-06-at-13.52.57.png)

In the app, you can click any class or break to see with whom you share the hour. It's no longer a guessing game! ✓

🥳
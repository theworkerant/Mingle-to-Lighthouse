### A hack of an import script for Mingle to Lighthouse

This code has been extracted out of a production Rails application. Mingle -> Lighthouse integration is hairy because the statuses don't always match up one-to-one depending on how your Mingle project is organized. The script tags all imported tickets with "mingle" and a delete task to get rid of them all on the Lighthouse side, for convenience.

While tickets imported from Mingle and subsequently updated in Mingle can then be updated in Lighthouse on the next sync, the script will only do so if the lighthouse ticket hasn't been touched since. All in all, this script may give you a head start, but please make sure everything lines up before just running it on your important projects.

## Requirements 

  - lightouse_api
  - A lighthouse account and token
  - A mingle account to import from
  - Mingle class requires ActiveRecord::Base for RESTful API stuff
  
## Usage

  - Throw mingle2lighthouse.rake in your tasks directory
  - Throw mingle2lighthouse.rb in your initializers 
  - Map your statuses, enter your credentials for both APIs between Mingle and Lighthouse in might2lighthouse.rb
  - Run it as a rake task "lighthouse:sync_mingle" 
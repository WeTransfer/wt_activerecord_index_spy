## 0.3.0
* add support for PostgreSQL (unfortunately all results are uncertain)
* add support for Ruby >= 2.5 and Activerecord >= 4
* sort lines in the HTML report by certainity_level, identifier, query
* improve the query analyser to not analyse a query again if a similar query was analysed before with a prepared statement (Postgres use prepared statements by default)
* improve the logic to detect if a query was fired from a test file or not
* remove the auto require for the module TestHelpers

## 0.2.0
* Improve RSpec matcher to cache EXPLAIN results

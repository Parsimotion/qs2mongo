# qs2mongo

[![NPM version](https://badge.fury.io/js/qs2mongo.png)](http://badge.fury.io/js/qs2mongo)

### Querystring to mongo mapper

Builds filters, projections and options for mongoose queries
- In your querystring: 
  - `attributes=comma,separated,fields` maps to projection `{ comma: 1, separated: 1, fields: 1 }`
  - `limit=1,offset=2` maps to options `{ limit: 1, offset: 2 }`
  - Sorts
    - Ascending: `sort=field` maps to options `{ sort: { field: 1 } }`
    - Descending: `sort=-field` maps to options `{ sort: { field: -1 } }`
  - Any other key maps to a mongo filter. Available options are:
    - strict: `key=value` is `{ key: value }`
    - not strict: `key=value` is `{ key: /value/gi }`
    - $or: `key,anotherKey=value` is `$or: [{key:value}, {anotherKey:value}]`
    - $in : `key__in=a,b,c` is `key: $in: ["a","b","c"]`
    - unary operators: `key__gt=value` is `{key: { $gt: "value"} }`

#### Basic usage

``` Coffeescript
Qs2Mongo = require ("qs2mongo")

#Bind types to mongoose schema
qs2mongo = Qs2Mongo.MongooseSchema YourMongooseSchema, {...otherOptions...}

#Or manually specify types
qs2mongo = Qs2Mongo.ManualSchema {
  filterableBooleans, 
  filterableNumbers,
  filterableDates,
  filterableObjectIds
}, {...otherOptions...}
```

``` Coffeescript

#... 
anEndpoint: (req, res): =>
  { filters, projection, options } = qs2mongo.parse req
```

#### Usage as middleware

``` Coffeescript
Qs2Mongo = require ("qs2mongo")
config = ...
qs2mongo = new Qs2Mongo config
#... 
router.use qs2mongo.middleware

#... 
anEndpoint: (req, res): =>
  { filters, projection, options } = req.mongo

```

#### Config

``` Coffeescript
  {
    defaultSort, 
    idField = "id", 
    multigetIdField = "_id", 
    omitableProperties = Qs2Mongo.defaultOmitableProperties
  }
```


## Advanced

Default driver is mongodb. If you'd like to use a custom mongodb driver, you must provide your own type conversion implementation as follows:

``` Coffesscript
{
  toObjectId: (it) -> #your conversion

  toNumber: (it) -> #your conversion

  toBoolean: (it) -> #your conversion

  toDate: (it) -> #your conversion
}
```
Note: Your conversion must return the properly converted value if `it` is valid or `undefined` otherwise.

Specify the path to your implementation in process.env.QS_TRANSFORMER_DRIVER


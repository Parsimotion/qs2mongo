{ ObjectId } = require("mongodb")

#it puede llegar a ser una regex, por eso el '.source'.
_value = (it) -> it.source or it

_stringToBoolean = (value,_default) ->
  (value?.toLowerCase?() or _default?.toString()) is 'true'

module.exports =
  new class TypeTransformerDriver

    toObjectId: (it) -> new ObjectId _value it

    toNumber: (it) -> Number _value it

    toBoolean: (it) -> _stringToBoolean _value it

    toDate: (it) -> new Date _value it


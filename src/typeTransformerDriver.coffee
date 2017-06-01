{ ObjectId } = require("mongodb")

#it puede llegar a ser una regex, por eso el '.source'.
_value = (it) -> it.source or it

_stringToBoolean = (value,_default) ->
  (value?.toLowerCase?() or _default?.toString()) is 'true'
_toNumber = (it) -> Number _value it

module.exports =
  new class TypeTransformerDriver

    toObjectId: (it) -> new ObjectId _value it
    
    toNumber: (it) -> 
      values = "#{_value it}".split(',').map _toNumber
      if values.length is 1 then values[0] else values

    toBoolean: (it) -> _stringToBoolean _value it

    toDate: (it) -> new Date _value it


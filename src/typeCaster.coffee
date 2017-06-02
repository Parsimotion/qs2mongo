_ = require("lodash")
TypeTransformerDriver = require(process.env.QS_TRANSFORMER_DRIVER or "./typeTransformerDriver")

module.exports = 
  class TypeCaster
    @operators: [ 'lt', 'gt','lte', 'gte','in','nin','eq' ] #TODO: Sacar esto de aca

    constructor: (opts) -> 
      _.assign @, opts
      #flowRight === compose
      @castFilters = 
        _.flowRight @_castNumberFilters, @_castDateFilters, @_castBooleanFilters, @_castObjectIdFilters

    _castObjectIdFilters: (query) =>
      @_transformFilters query, @objectIds, TypeTransformerDriver.toObjectId
    
    _castNumberFilters: (query) =>
      @_transformFilters query, @numbers, TypeTransformerDriver.toNumber
    
    _castBooleanFilters: (query) =>
      @_transformFilters query, @booleans, TypeTransformerDriver.toBoolean

    _castDateFilters: (query) =>
      @_transformFilters query, @dates, TypeTransformerDriver.toDate

    _mergeWithOperators: (fields) =>
      _.flatMap fields, (field) =>
        TypeCaster.operators.map (it) => "#{field}__#{it}"
          .concat field
      #This has effect
    _transformFilters: (query, fields, transformation) =>
      filtersWithOperators = @_mergeWithOperators fields
      filtersWithOperators.forEach (field) =>
        query[field] = transformation query[field] if query[field]?
      query

    _stringToBoolean: (value,_default) ->
      (value?.toLowerCase?() or _default?.toString()) is 'true'

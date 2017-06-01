module.exports = 
  class Manual
    constructor: ({
      @filterableBooleans = []
      @filterableDates = []
      @filterableNumbers = []
      @filterableObjectIds = []
    }) ->
      
    numbers: => @filterableNumbers

    dates: => @filterableDates
    
    booleans: => @filterableBooleans

    objectIds: => @filterableObjectIds

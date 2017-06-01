module.exports = 
  class Manual
    constructor: ({
      @filterableBooleans = []
      @filterableDates = []
      @filterableNumbers = []
    }) ->
      
    numbers: => @filterableNumbers

    dates: => @filterableDates
    
    booleans: => @filterableBooleans

module.exports = 
  class MySchema 
    constructor: ({
      @filterableBooleans = []
      @filterableDates = []
      @filterableNumbers = []
    }) ->
      
    numbers: => @filterableNumbers

    dates: => @filterableDates
    
    booleans: => @filterableBooleans

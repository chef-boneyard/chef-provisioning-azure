module ChefMetalAzure
class Constants
  class Transport
    HTTP = 'http'
    HTTPS = 'https'
  end

  class MachineSize
    # Put in machine specs here...
    EXTRASMALL = 'ExtraSmall'
    # What is this?
    SMALL = 'Small'
    # Are these now A2?
    MEDIUM = 'Medium'
    LARGE = 'Large'
    XLARGE = 'ExtraLarge'
    A5 = 'A5'
    A6 = 'A6'
    A7 = 'A7'
    BASIC_A0 = 'Basic_A0'
    BASIC_A1 = 'Basic_A1'
    BASIC_A2 = 'Basic_A2'
    BASIC_A3 = 'Basic_A3'
    BASIC_A4 = 'Basic_A4'
  end
end
end
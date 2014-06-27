## Generated from localized_string.proto for 
require "beefcake"


class LocalizedString
  include Beefcake::Message

  module Locale
    AF = 0
    AM = 1
    AR = 2
    AR_XB = 3
    BG = 4
    BN = 5
    CA = 6
    CS = 7
    CY = 8
    DA = 9
    DE = 10
    DE_AT = 11
    DE_CH = 12
    EL = 13
    EN = 14
    EN_GB = 15
    EN_IE = 16
    EN_IN = 17
    EN_SG = 18
    EN_XA = 19
    EN_XC = 20
    EN_ZA = 21
    ES = 22
    ES_419 = 23
    ES_AR = 24
    ES_BO = 25
    ES_CL = 26
    ES_CO = 27
    ES_CR = 28
    ES_DO = 29
    ES_EC = 30
    ES_GT = 31
    ES_HN = 32
    ES_MX = 33
    ES_NI = 34
    ES_PA = 35
    ES_PE = 36
    ES_PR = 37
    ES_PY = 38
    ES_SV = 39
    ES_US = 40
    ES_UY = 41
    ES_VE = 42
    ET = 43
    EU = 44
    FA = 45
    FI = 46
    FR = 47
    FR_CA = 48
    FR_CH = 49
    GL = 50
    GU = 51
    HE = 52
    HI = 53
    HR = 54
    HU = 55
    HY = 56
    ID = 57
    IN = 58
    IT = 59
    JA = 60
    KA = 61
    KM = 62
    KN = 63
    KO = 64
    LN = 65
    LO = 66
    LT = 67
    LV = 68
    ML = 69
    MO = 70
    MR = 71
    MS = 72
    NB = 73
    NE = 74
    NL = 75
    NO = 76
    PL = 77
    PT = 78
    PT_BR = 79
    PT_PT = 80
    RM = 81
    RO = 82
    RU = 83
    SK = 84
    SL = 85
    SR = 86
    SR_LATN = 87
    SV = 88
    SW = 89
    TA = 90
    TE = 91
    TH = 92
    TL = 93
    TR = 94
    UK = 95
    UR = 96
    VI = 97
    ZH = 98
    ZH_CN = 99
    ZH_HK = 100
    ZH_TW = 101
    ZU = 102
  end
end

class LocalizedString
  optional :locale, LocalizedString::Locale, 1
  optional :value, :string, 2
end

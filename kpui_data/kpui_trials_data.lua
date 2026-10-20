-- KelaPadUI trial and arena achievement/portal data.
-- Pulled from Pithka's Achievement Tracker; moved from KelaPadUI.lua.

-- Trials and Arenas pulled from Pithka's Achievement Tracker
KELA_TRIALS_DATA = {
    -- Trials
    ["VHRC"] = {NAME="Hel Ra Citadel",         ABBV="VHRC", VET=1474, PHM1=nil,  PHM1NAME="",         PHM2=nil,  PHM2NAME="",        HM=1136,  HMNAME="Celest. Warrior", TRI=nil,  TRINAME="",                    EXT=nil,  EXTNAME="",                      DLC=false,   LBINDEX=1,   portID= 230,  TYPE="trial"},
    ["VAA"] =  {NAME="Aetherian Archive",      ABBV="VAA",  VET=1503, PHM1=nil,  PHM1NAME="",         PHM2=nil,  PHM2NAME="",        HM=1137,  HMNAME="Celest. Mage",    TRI=nil,  TRINAME="",                    EXT=nil,  EXTNAME="",                      DLC=false,   LBINDEX=2,   portID= 231,  TYPE="trial"},
    ["VSO"] =  {NAME="Sanctum Ophidia",        ABBV="VSO",  VET=1462, PHM1=nil,  PHM1NAME="",         PHM2=nil,  PHM2NAME="",        HM=1138,  HMNAME="Celest. Serpent", TRI=nil,  TRINAME="",                    EXT=nil,  EXTNAME="",                      DLC=false,   LBINDEX=3,   portID= 232,  TYPE="trial"},
    ["VMOL"] = {NAME="Maw of Lorkhaj",         ABBV="VMOL", VET=1368, PHM1=nil,  PHM1NAME="",         PHM2=nil,  PHM2NAME="",        HM=1344,  HMNAME="Rakkhat",         TRI=nil,  TRINAME="",                    EXT=1391, EXTNAME="Dro-m'Athra Destroyer", DLC=true,    LBINDEX=5,   portID= 258,  TYPE="trial"},
    ["VHOF"] = {NAME="Halls of Fabrication",   ABBV="VHOF", VET=1810, PHM1=nil,  PHM1NAME="",         PHM2=nil,  PHM2NAME="",        HM=1829,  HMNAME="Assembly Gen.",   TRI=1838, TRINAME="Tick-Tock Tormentor", EXT=1836, EXTNAME="The Dynamo",            DLC=true,    LBINDEX=7,   portID= 331,  TYPE="trial"},
    ["VAS"] =  {NAME="Asylum Sanctorium",      ABBV="VAS",  VET=2077, PHM1=2085, PHM1NAME="+Llothis", PHM2=2086, PHM2NAME="+Felms",  HM=2079,  HMNAME="vAS +2",          TRI=2087, TRINAME="Saintly Savior",      EXT=2075, EXTNAME="Immortal Redeemer",     DLC=true,    LBINDEX=8,   portID= 346,  TYPE="trial"},
    ["VCR"] =  {NAME="Cloudrest",              ABBV="VCR",  VET=2133, PHM1=2134, PHM1NAME="vCR +1",   PHM2=2135, PHM2NAME="vCR +2",  HM=2136,  HMNAME="vCR +3",          TRI=2139, TRINAME="Gryphon Heart",       EXT=2140, EXTNAME="Welkynar Liberator",    DLC=true,    LBINDEX=9,   portID= 364,  TYPE="trial"},

    ["VSS"] =  {NAME="Sunspire",               ABBV="VSS",  VET=2435, PHM1=2469, PHM1NAME="Yolna",    PHM2=2470, PHM2NAME="Lokke",   HM=2466,  HMNAME="Nahvi",           TRI=2467, TRINAME="Godslayer",           EXT=2468, EXTNAME="Hand of Alkosh",        DLC=true,    LBINDEX=12,  portID= 399,  TYPE="trial"},
    ["VKA"] =  {NAME="Kyne's Aegis",           ABBV="VKA",  VET=2734, PHM1=2736, PHM1NAME="Yandir",   PHM2=2737, PHM2NAME="Vrol",    HM=2739,  HMNAME="Falgravn",        TRI=2740, TRINAME="Kyne's Wrath",        EXT=2746, EXTNAME="Dawnbringer",           DLC=true,    LBINDEX=13,  portID= 434,  TYPE="trial"},
    ["VRG"] =  {NAME="Rockgrove",              ABBV="VRG",  VET=2987, PHM1=3005, PHM1NAME="Oaxiltso", PHM2=3006, PHM2NAME="Bahsei",  HM=3007,  HMNAME="Xalvakka",        TRI=3003, TRINAME="Planesbreaker",       EXT=3004, EXTNAME="Daedric Bane",          DLC=true,    LBINDEX=15,  portID= 468,  TYPE="trial"},
    ["VDSR"] = {NAME="Dreadsail Reef",         ABBV="VDSR", VET=3244, PHM1=3250, PHM1NAME="Twins",    PHM2=3251, PHM2NAME="Reef",    HM=3252,  HMNAME="Taleria",         TRI=3248, TRINAME="Soul of the Squall",  EXT=3249, EXTNAME="Swashbuckler Supreme",  DLC=true,    LBINDEX=16,  portID= 488,  TYPE="trial"},
    ["VSE"] =  {NAME="Sanity's Edge",          ABBV="VSE",  VET=3560, PHM1=3566, PHM1NAME="Yaseyla",  PHM2=3567, PHM2NAME="Twelvane",HM=3568,  HMNAME="Ansuul",          TRI=3564, TRINAME="Dream Master",        EXT=3565, EXTNAME="Mindmender",            DLC=true,    LBINDEX=17,  portID= 534,  TYPE="trial"},
	["VLC"] =  {NAME="Lucent Citadel",         ABBV="LC",  VET=4015, PHM1=4021, PHM1NAME="Count",    PHM2=4022, PHM2NAME="Orphic",  HM=4023,  HMNAME="Arcane Knot",     TRI=4019, TRINAME="Unstoppable",         EXT=4020, EXTNAME="Arcane Stabilizer",     DLC=true,    LBINDEX=18,  portID= 568,  TYPE="trial"},
	["VOC"] =  {NAME="Ossein Cage",            ABBV="OC",  VET=4268, PHM1=4274, PHM1NAME="Shapers",  PHM2=4275, PHM2NAME="Jynorah", HM=4276, HMNAME="Kazpian",         TRI=4272, TRINAME="Misery's Master",     EXT=4273, EXTNAME="Cista Breaker",         DLC=true,    LBINDEX=19,  portID= 589,    TYPE="trial"},


    -- Arenas   
    ["VDSA"] = {NAME="Dragonstar Arena",       ABBV="VDSA",  VET=1140, TRI=nil,   TRINAME="",                   EXT=nil,  EXTNAME="",                      DLC=false,   LBINDEX=4,   portID= 270,  TYPE="arena"},    
    ["VBRP"] = {NAME="Blackrose Prison",       ABBV="VBRP",  VET=2363, TRI=2368,  TRINAME="Unchained",          EXT=2372, EXTNAME="A Thrilling Trifecta",  DLC=false,   LBINDEX=11,  portID= 378,  TYPE="arena"},
}

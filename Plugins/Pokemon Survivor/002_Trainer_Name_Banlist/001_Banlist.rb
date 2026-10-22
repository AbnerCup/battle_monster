#===============================================================================
# Pokemon Survivor - Trainer name ban list
#===============================================================================

module PokemonSurvivor
  remove_const(:BANNED_TRAINER_NAMES) if const_defined?(:BANNED_TRAINER_NAMES)
  remove_const(:EXACT_BANNED_TRAINER_NAMES) if const_defined?(:EXACT_BANNED_TRAINER_NAMES)

  # Trainer names are limited to A-Z and 7 letters. The validator rejects a name
  # when it contains one of these entries, so avoid harmless short fragments.
  BANNED_TRAINER_NAMES = [
    # Reserved/system names
    "ADMIN", "ADMINS", "MOD", "MODS", "STAFF", "DEV", "DEVS", "OWNER",
    "SYSTEM", "SUPPORT", "PLAYER", "TEST", "TESTER", "NULL", "NONE",
    "GUEST", "SCORE", "SERVER", "ONLINE", "OFFLINE", "BOT", "BOTS",
    "ROOT", "SUPER", "MASTER", "GM", "GAME", "RANK", "RANKER", "LEADER",

    # English profanity/offensive names
    "FUCK", "FUCKER", "FUCKU", "FUK", "FUKER", "FUKK", "SHIT", "SHITE",
    "SHITER", "BITCH", "BTCH", "BASTARD", "PUSSY", "DICK", "DICKS",
    "DICKY", "CUNT", "CUNTS", "ASSHOLE", "ARSE", "PRICK", "WANKER",
    "WHORE", "SLUT", "DOUCHE", "MORON", "IDIOT", "RETARD", "LOSER",
    "NOOB", "NUB", "SWINE", "MONKEY", "SCUMBAG", "SCUM", "TRASH",
    "GARBAGE", "TOXIC", "SIMP", "CUCK", "BIMBO", "SKANK", "CRACK",
    "CRACKER", "JERK", "TWERP", "FREAK", "PERV", "PERVERT", "DRUGGY",

    # French profanity/offensive names without accents
    "MERDE", "MERDES", "PUTAIN", "PUTE", "PUTES", "SALOPE", "SALOP",
    "SALAUD", "CONARD", "CONNARD", "CONNAS", "CONNE", "CONNES", "ENCULE",
    "ENCULER", "ENCULES", "TAPETTE", "PETASSE", "BATARD", "BOUFFON",
    "DEBILE", "CRETIN", "POURRI", "ORDURE", "ENFOIRE", "ENFOIR",
    "IDIOT", "NUL", "NULLOS", "CASSOS", "BLAIREA", "BOULET",

    # German profanity/offensive names
    "SCHEIS", "SCHEISS", "ARSCH", "FICK", "FICKER", "FOTZE", "FOTZEN",
    "HURE", "HUREN", "SCHLAM", "SCHLAMM", "WICHS", "WICHSER", "IDIOT",
    "DEPP", "OPFER", "SPAST", "DUMMKOP", "SCHWEIN", "TROTTEL", "PENNER",
    "SAU", "SAUSACK", "MISTKER", "BLOED", "DRECK", "ABSCHA",

    # Portuguese profanity/offensive names
    "MERDA", "PORRA", "CARALHO", "CUZAO", "CUZONA", "BUCETA", "PUTA",
    "PUTO", "PUTAS", "FILHDP", "VIADO", "VEADO", "PIRANHA", "IDIOTA",
    "BURRO", "OTARIO", "BABACA", "CORNO", "ARROMBA", "PORCO", "VACA",
    "VADIA", "BOSTA", "TROUXA", "PALHACO", "CRETINO", "IMBECIL",
    "CANALHA", "NOJENTO", "MALDITO", "PILANTR",

    # Spanish profanity/offensive names
    "MIERDA", "JODER", "JODIDO", "JODIDA", "PUTA", "PUTO", "PUTOS",
    "CABRON", "CABRONA", "COJON", "COJONES", "PENDEJO", "PENDEJA",
    "PENDEJ", "GILIPO", "MARICA", "MARICON", "ZORRA", "ZORRO", "IDIOTA",
    "TONTO", "TONTA", "IMBECIL", "MAMON", "MAMONA", "CAGADA", "CERDO",
    "CERDA", "PERRA", "MALDITO", "MALDITA", "ESTUPID", "PAYASO",
    "BASURA", "CABRONS", "CULERO", "CULERA", "CONO",

    # Hate slurs and extremist/historical references
    "NIGGER", "NIGGA", "NEGRO", "NEGRER", "NEGER", "KIKE", "CHINK", "GOOK",
    "WETBACK", "FAGGOT", "DYKE", "TRANNY", "RAGHEAD", "TOWEL", "GYPSY",
    "GIPSY", "KRAUT", "NAZI", "NAZIS", "HITLER", "ADOLF", "FUHRER",
    "GESTAPO", "GOEBB", "GOEBBEL", "GOERING", "HIMMLER", "STALIN",
    "FRANCO", "MUSSOLI", "PINOCHE", "POLPOT", "BINLADN", "OSAMA",
    "ISIS", "DAESH", "TERROR", "JIHAD", "KLAN", "KLANER"
  ].uniq.freeze

  # Exact-only entries are intentionally short. They are banned as full names,
  # but they do not block longer innocent names that merely contain the letters.
  EXACT_BANNED_TRAINER_NAMES = [
    # English/online short insults and abuse
    "ASS", "ARSE", "AZZ", "PIG", "PIGS", "RAT", "RATS", "DOG", "DOGS",
    "APE", "APES", "FAG", "GAY", "HOMO", "SIMP", "CUCK", "NOOB", "NUB",
    "SUCK", "SUK", "DIE", "KYS", "KILL", "DEAD", "HATE", "SCUM", "TRASH",
    "TOXIC", "PERV", "JERK", "WORM", "CLOWN", "FOOL", "DUMB", "DUMBO",

    # French short/ambiguous names banned globally when exact
    "BIT", "BITE", "BITES", "BITEZ", "BITTE", "CON", "CONS", "CONNE",
    "CUL", "CACA", "PIPI", "PIS", "PUT", "PUTE", "PD", "FDP", "NTM",
    "TG", "NUL", "NULS", "BLET", "CRADO", "PORC", "GROS", "GOGOL",

    # German short/ambiguous names banned globally when exact
    "SAU", "SAUEN", "HURE", "HUREN", "DEPP", "FICK", "ARSCH", "DRECK",
    "MIST", "BLUT", "DOOF", "IDIOT", "OPFER", "SPAST", "FOTZE",

    # Portuguese short/ambiguous names banned globally when exact
    "CU", "CUZAO", "CUZ", "PUTA", "PUTO", "MERDA", "PORRA", "VACA",
    "PORCO", "CORNO", "BURRO", "BOSTA", "VIADO", "VEADO", "BOBO",

    # Spanish short/ambiguous names banned globally when exact
    "CULO", "PUTA", "PUTO", "PUTOS", "CONO", "COJON", "ZORRA", "ZORRO",
    "TONTO", "TONTA", "CERDO", "CERDA", "PERRA", "MAMON", "MAMONA",

    # Hate/extremism short forms
    "WOP", "DAGO", "PAKI", "KLAN", "KKK", "SS", "MAO", "JEW", "JEWS",
    "NEG", "NAZI", "ISIS", "NAZIS"
  ].uniq.freeze
end





{-# LANGUAGE CPP #-}
module Hledger.Web.WebOptions
where
import Prelude
import Data.Default
#if !MIN_VERSION_base(4,8,0)
import Data.Functor.Compat ((<$>))
#endif
import Data.Maybe

import Hledger.Cli hiding (progname,version,prognameandversion)
import Settings

progname, version :: String
progname = "hledger-web"
#ifdef VERSION
version = VERSION
#else
version = ""
#endif
prognameandversion :: String
prognameandversion = progname ++ " " ++ version :: String

defbaseurlexample :: String
defbaseurlexample = (reverse $ drop 4 $ reverse $ defbaseurl defport) ++ "PORT"

webflags :: [Flag [([Char], [Char])]]
webflags = [
  flagNone ["server"]   (setboolopt "server") ("log requests, and don't browse or auto-exit")
 ,flagReq  ["port"]     (\s opts -> Right $ setopt "port" s opts) "PORT" ("set the tcp port (default: "++show defport++")")
 ,flagReq  ["base-url"] (\s opts -> Right $ setopt "base-url" s opts) "BASEURL" ("set the base url (default: "++defbaseurlexample++")")
 ,flagReq  ["file-url"] (\s opts -> Right $ setopt "file-url" s opts) "FILEURL" ("set the static files url (default: BASEURL/static)")
 ]

webmode :: Mode [([Char], [Char])]
webmode =  (mode "hledger-web" [("command","web")]
            "start serving the hledger web interface"
            (argsFlag "[PATTERNS]") []){
              modeGroupFlags = Group {
                                groupUnnamed = webflags
                               ,groupHidden = [flagNone ["binary-filename"] (setboolopt "binary-filename") "show the download filename for this executable, and exit"]
                               ,groupNamed = [generalflagsgroup1]
                               }
             ,modeHelpSuffix=[
                  -- "Reads your ~/.hledger.journal file, or another specified by $LEDGER_FILE or -f, and starts the full-window curses ui."
                 ]
           }

-- hledger-web options, used in hledger-web and above
data WebOpts = WebOpts {
     server_   :: Bool
    ,port_     :: Int
    ,base_url_ :: String
    ,file_url_ :: Maybe String
    ,cliopts_  :: CliOpts
 } deriving (Show)

defwebopts :: WebOpts
defwebopts = WebOpts
    def
    def
    def
    def
    def

-- instance Default WebOpts where def = defwebopts

rawOptsToWebOpts :: RawOpts -> IO WebOpts
rawOptsToWebOpts rawopts = checkWebOpts <$> do
  cliopts <- rawOptsToCliOpts rawopts
  let p = fromMaybe defport $ maybeintopt "port" rawopts
  return defwebopts {
              port_ = p
             ,server_ = boolopt "server" rawopts
             ,base_url_ = maybe (defbaseurl p) stripTrailingSlash $ maybestringopt "base-url" rawopts
             ,file_url_ = stripTrailingSlash <$> maybestringopt "file-url" rawopts
             ,cliopts_   = cliopts
             }
  where
    stripTrailingSlash = reverse . dropWhile (=='/') . reverse -- yesod don't like it

checkWebOpts :: WebOpts -> WebOpts
checkWebOpts = id

getHledgerWebOpts :: IO WebOpts
getHledgerWebOpts = processArgs webmode >>= return . decodeRawOpts >>= rawOptsToWebOpts


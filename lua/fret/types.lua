---@alias AltKeys 'lshift'|'rshift'
---@alias MapKeys 'fret_f'|'fret_F'|'fret_t'|'fret_T'
---@alias Direction 'forward'|'backward'
---@alias Hlgroup 'FretCandidateFirst'|'FretCandidateSecond'|'FretCandidateSub'|'FretAlternative'|'FretIgnore'
---@alias CharHighlight {[integer]:string,[integer]:Hlgroup}
---@alias Details {actual:string,char:string,altchar:string,level:integer,double:boolean,byteidx:integer,start_at:integer}
---@alias HintDetails {actual:string,level:integer,bytes:integer}

---@class Options
---@field fret_timeout integer
---@field fret_enable_kana boolean
---@field fret_enable_symbol boolean
---@field fret_repeat_notify boolean
---@field fret_hlmode string
---@field altkeys table<AltKeys,string>
---@field mapkeys table<MapKeys,string>

---@class Instance
---@field ns integer
---@field timer Timer
---@field hlgroup table<Hlgroup,string>
---@field bufnr integer
---@field winid integer
---@field conceallevel integer
---@field hlmode string
---@field notify boolean
---@field enable_kana boolean
---@field enable_symbol boolean
---@field timeout integer
---@field vcount integer
---@field mapkey string
---@field reversive boolean
---@field operative boolean
---@field till integer
---@field front_byteidx integer
---@field cur_row integer
---@field cur_col integer
---@field leftcol integer
---@field info_width integer
---@field line string
---@field keys Keys
---@field hints? table<integer,HintDetails>
---@field dotrepeat? string

---@class Keys
---@field level table<string,integer>
---@field ignore table<string,integer>
---@field detail Details
---@field mark_pos table<integer,integer>
---@field first_idx table<string,integer>
---@field second_idx table<string,integer>

---@class Fret
---@field public mapped_trigger boolean?
---@field public altkeys {[AltKeys]:string}
---@field public inst fun(self:self,mapkey:string,direction:Direction,till:integer):nil
---@field public playing fun(mapkey:string,direction:Direction,till:integer):nil
---@field public performing fun():nil
---@field public dotrepeat fun():nil
---@field public setup fun(opts:Options):boolean

---@class Session:Instance
---@field new fun(mapkey:string,direction:Direction,till:integer):Session
---@field set_line_informations fun(self:self):string?
---@field start_at_extmark fun(self:self,indices:string):fun(integer):integer
---@field store_key fun(self:self,char:string,idx:integer,byteidx:integer,start_at:integer,kana:boolean)
---@field get_inlay_hints fun(self:self,width:integer):table<integer,HintDetails>?
---@field get_keys fun(self:self,indices:string):string
---@field key_in fun(self:self):string?
---@field repeatable fun(self:self,count:integer):nil
---@field operable fun(self:self,conut:integer):string
---@field finish fun(self:self):nil
---@field get_markers fun(self:self,callback:fun(v:Details,count:integer):string):CharHighlight[]
---@field create_line_marker fun(self:self,width:integer,input:string,lower:string):CharHighlight[]
---@field attach_extmark fun(self:self,input?:string,lower?:string):nil
---@field related fun(self:self,input:string,lower:string):nil
---@field gain fun(self:self,input:string):nil

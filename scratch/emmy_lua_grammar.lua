local _ = [[
EmmyLua         <-  ({} '---' EmmyBody {} ShortComment)
                ->  EmmyLua
EmmySp          <-  (!'---@' !'---' Comment / %s / %nl)*
EmmyComments    <-  (EmmyComment (%nl EmmyComMulti / %nl EmmyComSingle)*)
EmmyComment     <-  EmmySp %s*                      {(!%nl .)*}
EmmyComMulti    <-  EmmySp '---|'         {} -> en  {(!%nl .)*}
EmmyComSingle   <-  EmmySp '---' !'@' %s* {} -> ' ' {(!%nl .)*}
EmmyBody        <-  '@class'    %s+ EmmyClass    -> EmmyClass
                /   '@type'     %s+ EmmyType     -> EmmyType
                /   '@alias'    %s+ EmmyAlias    -> EmmyAlias
                /   '@param'    %s+ EmmyParam    -> EmmyParam
                /   '@return'   %s+ EmmyReturn   -> EmmyReturn
                /   '@field'    %s+ EmmyField    -> EmmyField
                /   '@generic'  %s+ EmmyGeneric  -> EmmyGeneric
                /   '@vararg'   %s+ EmmyVararg   -> EmmyVararg
                /   '@language' %s+ EmmyLanguage -> EmmyLanguage
                /   '@see'      %s+ EmmySee      -> EmmySee
                /   '@overload' %s+ EmmyOverLoad -> EmmyOverLoad
                /               %s* EmmyComments -> EmmyComment
                /   EmmyIncomplete
EmmyName        <-  ({} {[a-zA-Z_] [a-zA-Z0-9_]*})
                ->  EmmyName
MustEmmyName    <-  EmmyName / DirtyEmmyName
DirtyEmmyName   <-  {} ->  DirtyEmmyName
EmmyLongName    <-  ({} {(!%nl .)+})
                ->  EmmyName
EmmyIncomplete  <-  MustEmmyName
                ->  EmmyIncomplete
EmmyClass       <-  (MustEmmyName EmmyParentClass?)
EmmyParentClass <-  %s* {} ':' %s* MustEmmyName
EmmyType        <-  EmmyTypeUnits EmmyTypeEnums
EmmyTypeUnits   <-  {|
                        EmmyTypeUnit?
                        (%s* '|' %s* !String EmmyTypeUnit)*
                    |}
EmmyTypeEnums   <-  {| EmmyTypeEnum* |}
EmmyTypeUnit    <-  EmmyFunctionType
                /   EmmyTableType
                /   EmmyArrayType
                /   EmmyCommonType
EmmyCommonType  <-  EmmyName
                ->  EmmyCommonType
EmmyTypeEnum    <-  %s* (%nl %s* '---')? '|'? EmmyEnum
                ->  EmmyTypeEnum
EmmyEnum        <-  %s* {'>'?} %s* String (EmmyEnumComment / (!%nl !'|' .)*)
EmmyEnumComment <-  %s* '#' %s* {(!%nl .)*}
EmmyAlias       <-  MustEmmyName %s* EmmyType EmmyTypeEnum*
EmmyParam       <-  MustEmmyName %s* EmmyType %s* EmmyOption %s* EmmyTypeEnum*
EmmyOption      <-  Table?
                ->  EmmyOption
EmmyReturn      <-  {} %nil     {} Table -> EmmyOption
                /   {} EmmyType {} EmmyOption
EmmyField       <-  (EmmyFieldAccess MustEmmyName %s* EmmyType)
EmmyFieldAccess <-  ({'public'}    Cut %s*)
                /   ({'protected'} Cut %s*)
                /   ({'private'}   Cut %s*)
                /   {} -> 'public'
EmmyGeneric     <-  EmmyGenericBlock
                    (%s* ',' %s* EmmyGenericBlock)*
EmmyGenericBlock<-  (MustEmmyName %s* (':' %s* EmmyType)?)
                ->  EmmyGenericBlock
EmmyVararg      <-  EmmyType
EmmyLanguage    <-  MustEmmyName
EmmyArrayType   <-  ({}    MustEmmyName -> EmmyCommonType {}      '[' DirtyBR)
                ->  EmmyArrayType
                /   ({} PL EmmyCommonType                 DirtyPR '[' DirtyBR)
                ->  EmmyArrayType
EmmyTableType   <-  ({} 'table' Cut '<' %s* EmmyType %s* ',' %s* EmmyType %s* '>' {})
                ->  EmmyTableType
EmmyFunctionType<-  ({} 'fun' Cut %s* EmmyFunctionArgs %s* EmmyFunctionRtns {})
                ->  EmmyFunctionType
EmmyFunctionArgs<-  ('(' %s* EmmyFunctionArg %s* (',' %s* EmmyFunctionArg %s*)* DirtyPR)
                ->  EmmyFunctionArgs
                /  '(' %nil DirtyPR -> None
                /   %nil
EmmyFunctionRtns<-  (':' %s* EmmyType (%s* ',' %s* EmmyType)*)
                ->  EmmyFunctionRtns
                /   %nil
EmmyFunctionArg <-  MustEmmyName %s* ':' %s* EmmyType
EmmySee         <-  {} MustEmmyName %s* '#' %s* MustEmmyName {}
EmmyOverLoad    <-  EmmyFunctionType
]]

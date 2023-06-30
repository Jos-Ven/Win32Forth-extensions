(( De BMI (Body Mass Index) wordt berekend door uw lichaamsgewicht te delen door uw lengte in het kwadraat.

3 BMI groter dan 30: u bent duidelijk te zwaar en krijgt het advies om af te vallen
2 BMI tussen 25 en 30: u bent te zwaar; probeer in elk geval niet zwaarder te worden en zo mogelijk iets af te vallen
1 BMI tussen 18,5 en 25: u heeft een gezond gewicht
0 BMI kleiner dan 18,5: u bent te licht of 20 ?? Quetelet-Index (QI) ))

needs Config.f
Anew bmi.f

25.4e 0.999998e f/  1000e f/  fconstant InchConv \ to meters
5e 11e f/                     fconstant LbsConv  \ to KG

: bmi ( f: kg meters - bmi )  fdup f* f/  ;

0 constant UnderWeight
1 constant HealthyWeight
2 constant TooHeavyWeight


 0.00e fvalue BmiVal

00.00e fvalue MinVal
40.00e fvalue MaxVal

18.5e  fconstant MinBmi      25e fvalue MaxBmi      \ Target range BMI
 0e    fvalue    MinWeight   80e fvalue MaxWeight   \ Target range Weight

25e    fconstant MaxBmiInclSingCutOff

21.75e fvalue AverageNormal

30e fvalue ObeseInclSingCutOff
30e fvalue obese

s" BmiConfig.dat" ConfigFile$ place

ConfigVariable LBs/Inches-
ConfigVariable SingCutoff-
Config$: DataFile$
Config$: Lenght$
ConfigVariable ShowObese-

: fwithin     ( f: n1 low high - ) ( - f1 ) \ f1=true if ((n1 >= low) & (n1 < high))
   2 fpick f>  f>= and ;

: ClassifyBmi ( f: bmi - ) ( - ID_bmi_classified )
     case
                fdup MinBmi         f<      true  of  UnderWeight    endof
          drop  fdup MinBmi MaxBmi  fwithin true  of  HealthyWeight  endof
          drop  fdup MaxBmi obese   fwithin true  of  TooHeavyWeight endof
         TooHeavyWeight swap
     endcase
   fdrop
;

: RevKg ( f: bmi meters - kg )   fdup f* f*  ;

: CalcAverageNormal ( - )  MaxBmi MinBmi f+ 2e f/ fto AverageNormal ;

: SingaporeCutoff ( f: - ) ( f: - )
  ObeseInclSingCutOff MaxBmiInclSingCutOff SingCutoff- @
        if   2.1e f- fswap 2.5e f- fswap
        then
  fto MaxBmi  fto obese
  CalcAverageNormal
 ;

: 1dec ( f: f - f2 ) 10e f* ftrunc 10e f/ ;

: BmiAnalyse  ( f: bmi length - ) ( - ID_bmi_classified ) \ sets: MinVal MaxVal
  fswap ClassifyBmi
  MinBmi fover RevKg 1dec fto MinWeight
  SingaporeCutoff
  MaxBmi fswap RevKg 1dec fto MaxWeight
  CalcAverageNormal
 ;

\s 

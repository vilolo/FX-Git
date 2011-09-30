//|-----------------------------------------------------------------------------------------|
//|                                                                           pluslinex.mqh |
//|                                                            Copyright � 2011, Dennis Lee |
//| Assert History                                                                          |
//| 2.00    New concept: Trailing trendline can be set to watch and trail the price.        |
//|            When price crosses the first time, the trendline will start to watch and     |
//|            trail the price at a gap (user specified+PipWide).                           |
//|            When price crosses the second time, the pending order will open as normal.   |
//| 1.32    Fixed main to use Points as argument.                                           |
//| 1.31    Fixed bug in LinexComment().                                                    |
//| 1.30    Default Trend logic is to buy and sell. Added option to turn off buy or sell:   |
//|             Linex1NoBuy                                                                 |
//|             Linex1NoSell                                                                |
//|             Linex2NoBuy                                                                 |
//|             Linex2NoSell                                                                |
//| 1.20    Comment has been changed to show:                                               |
//|             Basic settings                                                              |
//|             Trend logic                                                                 |
//| 1.10    Open orders are removed; replaced by return signals:                            |
//|             -1 Buy to open Magic 1                                                      |
//|             1 Sell to open Magic 1                                                      |
//|             -2 Buy to close Magic 1                                                     |
//|             2 Sell to close Magic 1                                                     |
//| 1.00    Copied from Linexcutor, functions that relate to trading trendlines:            |
//|             CloseOrders()   --> LinexCloseOrders()                                      |
//|             OpenLast()      --> LinexOpenLast()                                         |
//|             OpenOrd()       --> LinexOpenOrd()                                          |
//|             start()         --> Linex()                                                 |
//|                             --> LinexComment()                                          |
//|-----------------------------------------------------------------------------------------|
#property   copyright "Copyright � 2011, Dennis Lee"
#include    <stdlib.mqh>

//|-----------------------------------------------------------------------------------------|
//|                 P L U S L I N E X   E X T E R N A L   V A R I A B L E S                 |
//|-----------------------------------------------------------------------------------------|
extern   string   Linex1         = "linex1";
extern   bool     Linex1NoBuy    = false;
extern   bool     Linex1NoSell   = false;
extern   bool     Linex1NoMove   = false;
extern   string   Linex2         = "linex2";
extern   bool     Linex2NoBuy    = false;
extern   bool     Linex2NoSell   = false;
extern   bool     Linex2NoMove   = false;
extern   double   LinexPipLimit  = 3;
extern   double   LinexPipWide   = 3;
extern   double   LinexPipMove   = 20;
extern   int      Linex1Magic    = 20090206;
extern   int      Linex2Magic    = 20090207;
extern   bool     LinexOneTrade= false;

//|-----------------------------------------------------------------------------------------|
//|                           I N T E R N A L   V A R I A B L E S                           |
//|-----------------------------------------------------------------------------------------|
double   I_LineLevel, I_Hlimit, I_Llimit, I_Hlimit1, I_Llimit1;
double   II_LineLevel, II_Hlimit, II_Llimit, II_Hlimit1, II_Llimit1;
//-- Assert new concept trailing trendline
//       0 - not crossed yet; 1 - crossed once; 2 - crossed second
double   I_Mlimit, II_Mlimit;
double   I_LineLevelStart, II_LineLevelStart;
int      I_Status, II_Status;
string   LinexName="PlusLinex";
string   LinexVer="2.00";

//|-----------------------------------------------------------------------------------------|
//|                             I N I T I A L I Z A T I O N                                 |
//|-----------------------------------------------------------------------------------------|
void LinexInit()
{
//---- Automatically adjust to Full-Pip or Sub-Pip Accounts
   if (!Linex1NoBuy && !Linex1NoSell && !Linex1NoMove)
   {
      Linex1NoMove=true;
      Alert("Linex1 can move uni-directional only (User has to set Buy or Sell to False). Linex1NoMove has been set to True.");
   }
   if (!Linex2NoBuy && !Linex2NoSell && !Linex2NoMove)
   {
      Linex2NoMove=true;
      Alert("Linex2 can move uni-directional only (User has to set Buy or Sell to False). Linex2NoMove has been set to True.");
   }
}

//|-----------------------------------------------------------------------------------------|
//|                               M A I N   P R O C E D U R E                               |
//|-----------------------------------------------------------------------------------------|
int Linex(double Pts)
{
   // Check for Trendline and Determine the Limits
   // ============================================
   
   if (ObjectFind(Linex1)<0) I_LineLevel = -1;
   else
   {
      I_LineLevel = ObjectGetValueByShift(Linex1,0);
      ObjectSetText(Linex1, Linex1, 10, "Arial");
   }
   I_Hlimit=0; I_Llimit=0;
   if (I_LineLevel>0)
   {
//-- Assert new concept moving trendline - Stage 1 of 5: Record price of original line.
      if (I_Status==0 && !Linex1NoMove) I_LineLevelStart=I_LineLevel;
//-- Assert new concept moving trendline - Stage 4 of 5: Move trendline to narrow the gap with closing price.
      if (I_Status==1 && !Linex1NoMove)
      {
         double I_LinePrice1=ObjectGet(Linex1,OBJPROP_PRICE1);
         double I_LinePrice2=ObjectGet(Linex1,OBJPROP_PRICE2);
         if (!Linex1NoSell)
         {
            I_Mlimit=I_LineLevel+(LinexPipLimit+LinexPipMove)*Pts;
            if (Close[0]>I_Mlimit)
            {
               ObjectSet(Linex1,OBJPROP_PRICE1,I_LinePrice1+(LinexPipLimit+LinexPipMove)*Pts);
               ObjectSet(Linex1,OBJPROP_PRICE2,I_LinePrice2+(LinexPipLimit+LinexPipMove)*Pts);
            }
         }
         if (!Linex1NoBuy)
         {
            I_Mlimit=I_LineLevel-(LinexPipLimit+LinexPipMove)*Pts;
            if (Close[0]<I_Mlimit)
            {
               ObjectSet(Linex1,OBJPROP_PRICE1,I_LinePrice1-(LinexPipLimit+LinexPipMove)*Pts);
               ObjectSet(Linex1,OBJPROP_PRICE2,I_LinePrice2-(LinexPipLimit+LinexPipMove)*Pts);
            }
         }
      }   
      I_Hlimit  = I_LineLevel + (LinexPipLimit*Pts);
      I_Hlimit1 = I_Hlimit    + (LinexPipWide *Pts);
      I_Llimit  = I_LineLevel - (LinexPipLimit*Pts);
      I_Llimit1 = I_Llimit    - (LinexPipWide *Pts);
   }
   if (ObjectFind(Linex2)<0)   II_LineLevel = -1;
   else
   {
      II_LineLevel = ObjectGetValueByShift(Linex2,0);
      ObjectSetText(Linex2, Linex2, 10, "Arial");
   }
   II_Hlimit=0; II_Llimit=0;
   if (II_LineLevel>0)
   {
//-- Assert new concept moving trendline - Stage 1 of 5: Record price of original line.
      if (II_Status==0 && !Linex2NoMove) II_LineLevelStart=II_LineLevel;
//-- Assert new concept moving trendline - Stage 4 of 5: Move trendline to narrow the gap with closing price.
      if (II_Status==1 && !Linex2NoMove)
      {
         double II_LinePrice1=ObjectGet(Linex2,OBJPROP_PRICE1);
         double II_LinePrice2=ObjectGet(Linex2,OBJPROP_PRICE2);
         if (!Linex2NoSell)
         {
            II_Mlimit=II_LineLevel+(LinexPipLimit+LinexPipMove)*Pts;
            if (Close[0]>II_Mlimit)
            {
               ObjectSet(Linex2,OBJPROP_PRICE1,II_LinePrice1+(LinexPipLimit+LinexPipMove)*Pts);
               ObjectSet(Linex2,OBJPROP_PRICE2,II_LinePrice2+(LinexPipLimit+LinexPipMove)*Pts);
            }
         }
         if (!Linex1NoBuy)
         {
            II_Mlimit=II_LineLevel-(LinexPipLimit+LinexPipMove)*Pts;
            if (Close[0]<II_Mlimit)
            {
               ObjectSet(Linex2,OBJPROP_PRICE1,II_LinePrice1-(LinexPipLimit+LinexPipMove)*Pts);
               ObjectSet(Linex2,OBJPROP_PRICE2,II_LinePrice2-(LinexPipLimit+LinexPipMove)*Pts);
            }
         }
      }
      II_Hlimit  = II_LineLevel + (LinexPipLimit*Pts);
      II_Hlimit1 = II_Hlimit    + (LinexPipWide *Pts);
      II_Llimit  = II_LineLevel - (LinexPipLimit*Pts);
      II_Llimit1 = II_Llimit    - (LinexPipWide *Pts);
   }

   // Trade Decision
   // ==============
   if (I_LineLevel>0)
   {
      // Buy Zone
      // ========
      if (Close[0]>I_Hlimit && Close[0]<I_Hlimit1)
      {
      //-- Assert new concept moving trendline - Stage 2 of 5: Set Status from 0 (or 2) to 1.      
         if (!Linex1NoSell && I_Status!=1 && !Linex1NoMove) I_Status=1;
      //-- Assert Added option to turn off buy or sell
      //-- Assert new concept moving trendline - Stage 5 of 5: Open pending order and no need to reset Status.
         if (!Linex1NoBuy)
         {
            if (I_Status!=1 && !Linex1NoMove)   {}   // do nothing
            else
            //--  Assert Open orders are removed
               if (LinexOpenOrd(Linex1Magic)==0)   return(-1);
               else
                  if (LinexOpenLast(Linex1Magic)==OP_SELL)
                  {   
                     LinexCloseOrders(Linex1Magic);
                     if (LinexOneTrade && LinexOpenOrd(Linex2Magic)>0)    LinexCloseOrders(Linex2Magic);
                     Sleep(3000);
                  //--  Assert Open orders are removed
                      return(-1);
                  }
               //-- Assert new concept moving trendline - Stage 6 of 5: Reset Status from 1 to 0.
                  if (LinexOpenLast(Linex1Magic)==OP_BUY) I_Status=0;
         }
      }
      // Sell Zone
      // =========
   //--  Assert Added option to turn off buy or sell
      if (Close[0]<I_Llimit && Close[0]>I_Llimit1)
      {
      //-- Assert new concept moving trendline - Stage 2 of 5: Set Status from 0 (or 2) to 1.
         if (!Linex1NoBuy && I_Status!=1 && !Linex1NoMove) I_Status=1;
      //-- Assert Added option to turn off buy or sell
      //-- Assert new concept moving trendline - Stage 5 of 5: Open pending order.
         if (!Linex1NoSell)
         {
            if (I_Status!=1 && !Linex1NoMove)   {}   // do nothing
            else
            //--  Assert Open orders are removed
               if (LinexOpenOrd(Linex1Magic)==0)   return(1);
               else
                  if (LinexOpenLast(Linex1Magic)==OP_BUY)
                  {   
                     LinexCloseOrders(Linex1Magic); 
                     if (LinexOneTrade && LinexOpenOrd(Linex2Magic)>0)    LinexCloseOrders(Linex2Magic);
                     Sleep(3000); 
                  //--  Assert Open orders are removed
                     return(1);
                  }
               //-- Assert new concept moving trendline - Stage 6 of 5: Reset Status from 1 to 0.
                  if (LinexOpenLast(Linex1Magic)==OP_SELL) I_Status=0;
         }
      }
   }

   // Trade Decision
   // ==============
   if (II_LineLevel>0)
   {
      // Buy Zone
      // ========
      if (Close[0]>II_Hlimit && Close[0]<II_Hlimit1)
      {
      //-- Assert new concept moving trendline - Stage 2 of 5: Set Status from 0 (or 2) to 1.
         if (!Linex2NoSell && II_Status!=1 && !Linex2NoMove) II_Status=1;
      //-- Assert Added option to turn off buy or sell
      //-- Assert new concept moving trendline - Stage 5 of 5: Open pending order and no need to reset Status.
         if (!Linex2NoBuy)
         {
            if (II_Status!=1 && !Linex2NoMove)  {}    // do nothing
            else
            //--  Assert Open orders are removed
               if (LinexOpenOrd(Linex2Magic)==0)   return(-2);
               else
                  if (LinexOpenLast(Linex2Magic)==OP_SELL)
                  {   
                     LinexCloseOrders(Linex2Magic); 
                     if (LinexOneTrade && LinexOpenOrd(Linex1Magic)>0)    LinexCloseOrders(Linex1Magic);
                     Sleep(3000); 
                  //--  Assert Open orders are removed
                     return(-2);
                  }
               //-- Assert new concept moving trendline - Stage 6 of 5: Reset Status from 1 to 0.
                  if (LinexOpenLast(Linex2Magic)==OP_BUY) II_Status=0;
         }
      }
      // Sell Zone
      // =========
   //--  Assert Added option to turn off buy or sell
      if (Close[0]<II_Llimit && Close[0]>II_Llimit1)
      {
      //-- Assert new concept moving trendline - Stage 2 of 5: Set Status from 0 (or 2) to 1.
         if (!Linex2NoBuy && II_Status!=1 && !Linex2NoMove) II_Status=1;
      //-- Assert Added option to turn off buy or sell
      //-- Assert new concept moving trendline - Stage 5 of 5: Open pending order.
         if (!Linex2NoSell)
         {
            if (II_Status!=1 && !Linex2NoMove)  {}    // do nothing
            else
            //-- Assert Open orders are removed
               if (LinexOpenOrd(Linex2Magic)==0)   return(2);
               else
                  if (LinexOpenLast(Linex2Magic)==OP_BUY)
                  {   
                      LinexCloseOrders(Linex2Magic); 
                      if (LinexOneTrade && LinexOpenOrd(Linex1Magic)>0)    LinexCloseOrders(Linex1Magic);
                     Sleep(3000); 
                  //--  Assert Open orders are removed
                     return(2);
                  }
               //-- Assert new concept moving trendline - Stage 6 of 5: Reset Status from 1 to 0.
                  if (LinexOpenLast(Linex2Magic)==OP_SELL) II_Status=0;
         }
      }
   }
      
   return(0);
}

//|-----------------------------------------------------------------------------------------|
//|                                     C O M M E N T                                       |
//|-----------------------------------------------------------------------------------------|
string LinexComment(string cmt="")
{
   string strtmp = cmt+"  -->"+LinexName+" "+LinexVer+"<--";

   strtmp = strtmp + "\n    PipLimit=" + DoubleToStr(LinexPipLimit,0) + " PipWide=" + DoubleToStr(LinexPipWide,0);
   if (!Linex1NoMove || !Linex2NoMove) 
      strtmp = strtmp + " PipMove=" + DoubleToStr(LinexPipMove,0);
   if (I_LineLevel<0 && II_LineLevel<0) 
      strtmp = strtmp + "\n    No Active Trendlines.";
   if (I_LineLevel>=0)
   {
         strtmp = strtmp + "\n    " +Linex1+ " : " + DoubleToStr(I_LineLevel,Digits);
         if (!Linex1NoMove)
            switch (I_Status)
            {
               case 0:
                  strtmp = strtmp + " Waiting:";
                  break;
               case 1:
                  strtmp = strtmp + " Move " + DoubleToStr(MathAbs((I_LineLevel-I_LineLevelStart)/Pts),1) + " Pending:";
                  break;
            }
         else
            strtmp = strtmp + " Pending:";
         if (!Linex1NoBuy)    strtmp = strtmp + " (Buy >" + DoubleToStr(I_Hlimit,Digits) + " && <" + DoubleToStr(I_Hlimit1,Digits) + ")";
         if (!Linex1NoSell)   strtmp = strtmp + " (Sell >" + DoubleToStr(I_Llimit1,Digits) + " && <" + DoubleToStr(I_Llimit,Digits) + ")";

         strtmp = strtmp + " Last Order: ";  
         switch (LinexOpenLast(Linex2Magic))
         {
            case 0:  strtmp = strtmp + "BUY";    break;
            case 1:  strtmp = strtmp + "SELL";   break;
            default: strtmp = strtmp + "NIL";
         }
   }
   if (II_LineLevel>=0)
   {
         strtmp = strtmp + "\n    " +Linex2+ " : " + DoubleToStr(II_LineLevel,Digits);
         if (!Linex2NoMove)
            switch (II_Status)
            {
               case 0:
                  strtmp = strtmp + " Waiting:";
                  break;
               case 1:
                  strtmp = strtmp + " Move " + DoubleToStr(MathAbs((II_LineLevel-II_LineLevelStart)/Pts),1) + " Pending:";
                  break;
            }
         else
            strtmp = strtmp + " Pending:";
         if (!Linex2NoBuy)    strtmp = strtmp + " (Buy >" + DoubleToStr(II_Hlimit,Digits) + " && <" + DoubleToStr(II_Hlimit1,Digits) + ")";
         if (!Linex2NoSell)   strtmp = strtmp + " (Sell >" + DoubleToStr(II_Llimit1,Digits) + " && <" + DoubleToStr(II_Llimit,Digits) + ")";

         strtmp = strtmp + " Last Order: ";
         switch (LinexOpenLast(Linex2Magic))
         {
            case 0:  strtmp = strtmp + "BUY";    break;
            case 1:  strtmp = strtmp + "SELL";   break;
            default: strtmp = strtmp + "NIL";
         }
   }
                         
   strtmp = strtmp+"\n";
   return(strtmp);
}

//|-----------------------------------------------------------------------------------------|
//|                                O R D E R S   S T A T U S                                |
//|-----------------------------------------------------------------------------------------|
int LinexOpenLast(int mgc)
{
   int   last=-1;
      
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == mgc && OrderSymbol()==Symbol() && OrderType()<=1)
          last = OrderType();
   }      
   return(last);
}

int LinexOpenOrd(int mgc)
{
   int      ord=0;
   
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == mgc && OrderSymbol()==Symbol() && OrderType()<=1)
          ord++;
   }      
   return(ord);
}

//|-----------------------------------------------------------------------------------------|
//|                                  C L O S E  O R D E R S                                 |
//|-----------------------------------------------------------------------------------------|

void LinexCloseOrders(int mgc)
{
      int cnt,c,total=0,ticket=0,err=0;
      
      if (IsTradeAllowed() == true)
      { 
       total = OrdersTotal();
       for(cnt=total-1;cnt>=0;cnt--)
       {
          OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

          if(OrderMagicNumber()==mgc && OrderSymbol()==Symbol())
          {
             switch(OrderType())
             {
                case OP_BUY      :
                   for(c=0;c<5;c++)
                   {
                      RefreshRates();
                      OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),3,Yellow);
                      err = GetLastError();
                      if (err==0)   break;
                      else
                      {
                         Print("Errors Closing BUY order");
                         Print(ErrorDescription(err),", error ",err);
                         if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146)
                         { Sleep(5000); continue; }                            // Busy errors
                      }
                   }   
                   break;
               
                case OP_SELL     :
                   for(c=0;c<5;c++)
                   {
                      RefreshRates();
                      OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),3,Yellow);
                      err = GetLastError();
                      if (err==0) break;
                      else
                      {
                         Print("Errors Closing SELL order");
                         Print(ErrorDescription(err),", error ",err);
                         if(err==0 || err==4 || err==136 || err==137 || err==138 || err==146)
                         { Sleep(5000); continue; }                            // Busy errors
                      }
                   }   
                   break;
             } // end of switch
          } // end of if
       } // end of for
      }       
      return(0);
}

//|-----------------------------------------------------------------------------------------|
//|                       E N D   O F   E X P E R T   A D V I S O R                         |
//|-----------------------------------------------------------------------------------------|

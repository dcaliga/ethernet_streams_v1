
/*
 * Copyright 2005 SRC Computers, Inc.  All Rights Reserved.
 *
 *	Manufactured in the United States of America.
 *
 * SRC Computers, Inc.
 * 4240 N Nevada Avenue
 * Colorado Springs, CO 80907
 * (v) (719) 262-0213
 * (f) (719) 262-0223
 *
 * No permission has been granted to distribute this software
 * without the express permission of SRC Computers, Inc.
 *
 * This program is distributed WITHOUT ANY WARRANTY OF ANY KIND.
 */

#include <libmap.h>


void subr (int64_t In[], int64_t Out[], int nvec, int nsamp_4dma, int64_t *time, int mapnum) {

    OBM_BANK_A (AL,      int64_t, MAX_OBM_SIZE)
    OBM_BANK_B (BL,      int64_t, MAX_OBM_SIZE)

    int64_t t0, t1, t2;
    int i,n,total_nsamp,istart,cnt;
    
    Stream_64 SC,SA,SOut;
    Vec_Stream_64 VS_in;

    read_timer (&t0);


   printf ("nsamp_4dma %i\n",nsamp_4dma);

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SC, PORT_TO_STREAM, In, (nsamp_4dma+nvec)*sizeof(int64_t));
}
#pragma src section
{
    int i,j,new_vec,end_vec,iend;
    int64_t i64;

    new_vec = 1;
    end_vec = 0;
    for (i=0;i<nsamp_4dma+nvec;i++)  {
       get_stream_64 (&SC, &i64);

       if (new_vec )  iend    = i+i64;
       if (i == iend) end_vec = 1;
         
 printf ("i %i new %i end %i  i64 %lld\n",i,new_vec,end_vec,i64);

       if (new_vec)     put_vec_stream_64_header (&VS_in, i64);

       if (!new_vec)    put_vec_stream_64        (&VS_in, i64, 1);

       if (end_vec)             put_vec_stream_64_tail   (&VS_in, 0);

                      new_vec = 0;
       if (end_vec) { new_vec = 1; end_vec = 0; }
    }

    vec_stream_64_term (&VS_in);
}

#pragma src section
{
    int i,j;
    int64_t i64,j64,cnt,t0;

    //for (i=0;i<nvec;i++)  {
    while (is_vec_stream_64_active(&VS_in)) {

       get_vec_stream_64_header (&VS_in, &cnt);
   printf ("get vs cnt %lld\n",cnt);

       while (all_vec_streams_active()) {
       //for (j=0;j<cnt;j++)  {
          get_vec_stream_64 (&VS_in, &i64);

   printf ("get vs i64 %lld\n",i64);
          j64 = i64 + 100000;

          put_stream_64 (&SOut, j64, 1);
       }
       get_vec_stream_64_tail   (&VS_in, &t0);
    }

  printf ("end of Sout creation\n");
}
#pragma src section
{
    streamed_dma_cpu_64 (&SOut, STREAM_TO_PORT, Out, (nsamp_4dma)*sizeof(int64_t));
}
}
    }

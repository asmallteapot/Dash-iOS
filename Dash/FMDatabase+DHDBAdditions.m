//
//  FMDatabase+DHDBAdditions.m
//  Dash
//
//  Created by Ellen Teapot on 11/20/18.
//  Copyright © 2018 Kapeli. All rights reserved.
//

@import ObjectiveC.runtime;
@import SQLite3;

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabase+FTS3.h>
#import <unistd.h>

#ifndef DOCSETGENERATOR
    #import "DHPreferences.h"
#endif


#import "FMDatabase+DHDBAdditions.h"


void DHDBRankMatch(void *context, int argc, void **argv) {
    unsigned int *aMatchinfo;       /* Return value of matchinfo() */
    int nCol;                       /* Number of columns in the table */
    int nPhrase;                    /* Number of phrases in the query */
    int iPhrase;                    /* Current phrase */
    double score = 0.0;             /* Value to return */

    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table.
     */
    aMatchinfo = (unsigned int *)sqlite3_value_blob(argv[0]);
    nPhrase = aMatchinfo[0];
    nCol = aMatchinfo[1];
    if ( (argc - 1) > nCol ) goto wrong_number_args;


    /* Iterate through each phrase in the users query. */
    for(iPhrase=0; iPhrase<nPhrase; iPhrase++){

        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        unsigned int *aPhraseinfo = &aMatchinfo[2 + iPhrase*nCol*3];
        int iCol = 1;
        int nHitCount = aPhraseinfo[3*iCol];
        if( nHitCount>0 )
        {
            score += 1;
        }
    }

    sqlite3_result_double(context, score);
    return;

    /* Jump here if the wrong number of arguments are passed to this function */
wrong_number_args:
    sqlite3_result_error(context, "wrong number of arguments to function rank()", -1);
}


void DHDBCompress(void *context, int argc, void **argv) {
    if(argc == 1)
    {
        const char *text = (const char*)sqlite3_value_text(argv[0]);
        for(int i = 0; text[i] != '\0'; i++)
        {
            if(text[i] == ' ')
            {
                char compressed[i+3];
                compressed[0] = '`';
                compressed[1] = '`';
                memcpy(compressed+2, text, i);
                compressed[i+2] = '\0';
                sqlite3_result_text(context, compressed, -1, SQLITE_TRANSIENT);
                return;
            }
        }
        sqlite3_result_text(context, text, -1, SQLITE_TRANSIENT);
        return;
    }
    sqlite3_result_null(context);
}


void DHDBUncompress(void *context, int argc, void **argv) {
    if(argc == 1)
    {
        const char *text = (const char*)sqlite3_value_text(argv[0]);
        size_t len = strlen(text);
        if(len > 2 && text[0] == '`' && text[1] == '`')
        {
            size_t actualLen = len-2;
            size_t suffixLength = ((actualLen*(actualLen+1))/2)+actualLen+1;
            char suffix[suffixLength];
            int suffixIndex = 0;
            for(int i = 2; i < len; i++)
            {
                for(int j = i; j < len; j++)
                {
                    suffix[suffixIndex] = text[j];
                    ++suffixIndex;
                }
                if(text[i] == '`')
                {
                    for(int j = i+1; j < len; j++)
                    {
                        if(text[j] == '`')
                        {
                            i = j;
                            break;
                        }
                    }
                }
                if(i+1<len)
                {
                    suffix[suffixIndex] = ' ';
                    ++suffixIndex;
                }
            }
            suffix[suffixIndex] = '\0';
            sqlite3_result_text(context, suffix, -1, SQLITE_TRANSIENT);
        }
        else
        {
            sqlite3_result_text(context, text, -1, SQLITE_TRANSIENT);
        }
        return;
    }
    sqlite3_result_null(context);
}


@implementation FMDatabase (DHDBAdditions)

- (void)registerFTSExtensions;
{
    [self makeFunctionNamed:@"rank" arguments:-1 block:^(void * _Nonnull context, int argc, void * _Nonnull * _Nonnull argv) {
        DHDBRankMatch(context, argc, argv);
    }];

    [self makeFunctionNamed:@"dashCompress" arguments:1 block:^(void * _Nonnull context, int argc, void * _Nonnull * _Nonnull argv) {
        DHDBCompress(context, argc, argv);
    }];

    [self makeFunctionNamed:@"dashUncompress" arguments:1 block:^(void * _Nonnull context, int argc, void * _Nonnull * _Nonnull argv) {
        DHDBUncompress(context, argc, argv);
    }];
}

@end


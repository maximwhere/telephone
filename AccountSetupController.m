//
//  AccountSetupController.m
//  Telephone
//
//  Copyright (c) 2008-2009 Alexei Kuznetsov. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//  3. Neither the name of the copyright holder nor the names of contributors
//     may be used to endorse or promote products derived from this software
//     without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
//  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE THE COPYRIGHT HOLDER
//  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "AccountSetupController.h"


@implementation AccountSetupController

@synthesize fullNameField = fullNameField_;
@synthesize domainField = domainField_;
@synthesize usernameField = usernameField_;
@synthesize passwordField = passwordField_;
@synthesize fullNameInvalidDataView = fullNameInvalidDataView_;
@synthesize domainInvalidDataView = domainInvalidDataView_;
@synthesize usernameInvalidDataView = usernameInvalidDataView_;
@synthesize passwordInvalidDataView = passwordInvalidDataView_;
@synthesize defaultButton = defaultButton_;
@synthesize otherButton = otherButton_;

- (id)init {
  self = [super initWithWindowNibName:@"AccountSetup"];
  
  return self;
}

- (void)dealloc {
  [fullNameField_ release];
  [domainField_ release];
  [usernameField_ release];
  [passwordField_ release];
  [fullNameInvalidDataView_ release];
  [domainInvalidDataView_ release];
  [usernameInvalidDataView_ release];
  [passwordInvalidDataView_ release];
  [defaultButton_ release];
  [otherButton_ release];
  
  [super dealloc];
}

- (IBAction)closeSheet:(id)sender {
  [NSApp endSheet:[sender window]];
  [[sender window] orderOut:sender];
}

- (IBAction)addAccount:(id)sender {
  // Reset hidden states of the invalid data indicators.
  [[self fullNameInvalidDataView] setHidden:YES];
  [[self domainInvalidDataView] setHidden:YES];
  [[self usernameInvalidDataView] setHidden:YES];
  [[self passwordInvalidDataView] setHidden:YES];
  
  BOOL invalidFormData = NO;
  
  if ([[[self fullNameField] stringValue] length] == 0) {
    [[self fullNameInvalidDataView] setHidden:NO];
    invalidFormData = YES;
  }
  
  if ([[[self domainField] stringValue] length] == 0) {
    [[self domainInvalidDataView] setHidden:NO];
    invalidFormData = YES;
  }
  
  if ([[[self usernameField] stringValue] length] == 0) {
    [[self usernameInvalidDataView] setHidden:NO];
    invalidFormData = YES;
  }
  
  if ([[[self passwordField] stringValue] length] == 0) {
    [[self passwordInvalidDataView] setHidden:NO];
    invalidFormData = YES;
  }
  
  if (invalidFormData)
    return;
  
  NSMutableDictionary *accountDict = [NSMutableDictionary dictionary];
  [accountDict setObject:[NSNumber numberWithBool:YES] forKey:kAccountEnabled];
  [accountDict setObject:[[self fullNameField] stringValue] forKey:kFullName];
  [accountDict setObject:[[self domainField] stringValue] forKey:kDomain];
  [accountDict setObject:@"*" forKey:kRealm];
  [accountDict setObject:[[self usernameField] stringValue] forKey:kUsername];
  [accountDict setObject:[NSNumber numberWithInteger:0]
                  forKey:kReregistrationTime];
  [accountDict setObject:[NSNumber numberWithBool:NO]
                  forKey:kSubstitutePlusCharacter];
  [accountDict setObject:@"00" forKey:kPlusCharacterSubstitutionString];
  [accountDict setObject:[NSNumber numberWithBool:NO] forKey:kUseProxy];
  [accountDict setObject:@"" forKey:kProxyHost];
  [accountDict setObject:[NSNumber numberWithInteger:0] forKey:kProxyPort];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *savedAccounts
    = [NSMutableArray arrayWithArray:[defaults arrayForKey:kAccounts]];
  [savedAccounts addObject:accountDict];
  [defaults setObject:savedAccounts forKey:kAccounts];
  [defaults synchronize];
  
  [[self accountsTable] reloadData];
  
  BOOL success
    = [AKKeychain addItemWithServiceName:[NSString stringWithFormat:@"SIP: %@",
                                          [[self domainField] stringValue]]
                             accountName:[[self usernameField] stringValue]
                                password:[[self passwordField] stringValue]];
  
  [self closeSheet:sender];
  
  if (success) {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:AKPreferenceControllerDidAddAccountNotification
                   object:self
                 userInfo:accountDict];
  }
  
  // Set the selection to the new account
  NSUInteger index = [[defaults arrayForKey:kAccounts] count] - 1;
  if (index != 0) {
    [[self accountsTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                      byExtendingSelection:NO];
  }
}

@end

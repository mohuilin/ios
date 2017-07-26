//
//  LMBtcCurrencyManager.m
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBtcCurrencyManager.h"
#import "NetWorkOperationTool.h"
#import "LMCurrencyModel.h"
#import "LMRealmManager.h"
#import "Wallet.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "ConnectTool.h"
#import "LMWalletManager.h"
#import "LMCurrencyModel.h"
#import "LMBtcAddressManager.h"
#import "LMHistoryCacheManager.h"
#import "StringTool.h"


#ifdef __cplusplus
#if __cplusplus
extern "C" {
#include "bip39.h"
#include "ecies.h"
#include "pbkdf2.h"
}
#endif
#endif /* __cplusplus */

#include "key.h"
#include <sstream>

#include "base58.h"
#include "script.h"
#include "uint256.h"
#include "util.h"
#include "keydb.h"


#include <string>
#include <vector>

#include <openssl/aes.h>
#include <openssl/evp.h>
#include <openssl/bn.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>
#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/md5.h>


#include <boost/algorithm/string.hpp>
#include <boost/assign/list_of.hpp>
#include "json_spirit_reader_template.h"
#include "json_spirit_utils.h"
#include "json_spirit_writer_template.h"
#include "json_spirit_value.h"


@implementation LMBtcCurrencyManager

/**
 *  creat currency
 *
 */
- (void)createCurrency:(CurrencyType)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess payLoad:(NSString *)payLoad complete:(void (^)(LMCurrencyModel *currencyModel,NSError *error))complete {
    
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d ",(int)currency]] lastObject];
    if(currencyModel){
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"" code:CURRENCY_ISEXIST_135 userInfo:nil]);
        }
        return;
    }
    
    CreateCoinRequest *currencyCoin = [CreateCoinRequest new];
    currencyCoin.category = category;
    currencyCoin.masterAddress = masterAddess;
    currencyCoin.currency = (int)currency;
    currencyCoin.salt = salt;
    currencyCoin.payload = payLoad;

    [NetWorkOperationTool POSTWithUrlString:CreatCurrencyUrl postProtoData:currencyCoin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:CREAR_CURRENCY_FAILED_131 userInfo:nil]);
            }
        }else {
            // save db
            LMCurrencyModel *currencyModel = [LMCurrencyModel new];
            currencyModel.currency = (int)currency;
            currencyModel.category = category;
            currencyModel.salt = salt;
            currencyModel.masterAddress = masterAddess;
            currencyModel.status = 0;
            currencyModel.blance = 0;
            currencyModel.defaultAddress = masterAddess;
            currencyModel.payload = payLoad;
            // save address
            LMCurrencyAddress *addressModel = [LMCurrencyAddress new];
            addressModel.address = masterAddess;
            addressModel.index = 0;
            addressModel.status = 1;
            addressModel.label = nil;
            addressModel.currency = (int)currency;
            addressModel.balance = 0;
            [currencyModel.addressListArray addObject:addressModel];
            
            [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                [realm addOrUpdateObject:currencyModel];
            }];
            if (complete) {
                complete(currencyModel,nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
           complete(nil,[NSError errorWithDomain:@"" code:CREAR_CURRENCY_FAILED_131 userInfo:nil]);
        }
    }];
}
/**
 *  get currrency list
 *
 */
- (void)getCurrencyList:(void (^)(BOOL result,NSArray<Coin *> *coinList))complete{
    
    [NetWorkOperationTool POSTWithUrlString:GetCurrencyList postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,nil);
            }
            
        }else {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                Coins *coin = [Coins parseFromData:data error:nil];
                if (complete) {
                    complete(YES,coin.coinsArray);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,nil);
        }
    }];
}

/**
 *  set currency messageInfo
 *
 */
- (void)setCurrencyStatus:(int)status currency:(CurrencyType)currency complete:(void (^)(NSError *error))complete{
    Coin *coin = [Coin new];
    coin.currency = (int)currency;
    coin.status = status;
    
    [NetWorkOperationTool POSTWithUrlString:SetCurrencyInfo postProtoData:coin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        }else {
            if (complete) {
                complete(nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}

#pragma mark - encryption methods
- (NSString *)getPrivkeyBySeed:(NSString *)seed index:(int)index {
    char myRand[129] = {0};
    char *randomC = (char *) [seed UTF8String];
    sprintf(myRand, "%s", randomC);
    char privKey[512];
    GetBtcPrivKeyFromSeedBIP44(myRand, privKey, 44, 0, 0, 0, index);
    return [NSString stringWithFormat:@"%s", privKey];
}

-(NSString *)encodeValue:(NSString *)value password:(NSString *)password n:(int)n{
    if (n <= 0) {
        n = 17; //default
    }
    char *v = (char *)[value UTF8String];
    char *pass = (char *)[password UTF8String];
    std::string retString=connectWalletEncrypt(v,pass,n, 1);
    return [NSString stringWithFormat:@"%s",retString.c_str()];
}

-(void)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password complete:(void (^)(NSString *decodeValue,BOOL success))complete{
    char value[256];
    char *ev = (char *)[encryptValue UTF8String];
    char *pass = (char *)[password UTF8String];
    int result = connectWalletDecrypt(ev,pass,1, value);
    if (result == 1) {
        if (complete) {
            complete([NSString stringWithUTF8String:value],YES);
        }
    } else {
        if (complete) {
            complete(nil,NO);
        }
    }
}

- (BOOL)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password{
    char value[256];
    char *ev = (char *)[encryptValue UTF8String];
    char *pass = (char *)[password UTF8String];
    int result = connectWalletDecrypt(ev,pass,1, value);
    return result == 1;
}

// Data is converted to JsonString type
- (NSString *)ObjectTojsonString:(id)object {
    if (object == nil) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc] init];
    
    
    // The system comes with the method
    // /*
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0, jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0, mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}


std::string xtalkWalletSeedEncrypt(unsigned char *usrID, unsigned char *privKey, char *pwd, int n, int ver) {
    //  below is the process of E1
    unsigned char h[64];
    unsigned char chk[2];
    unsigned char usrIDAandPrivKey[XTALK_USRID_LEN + XTALK_PRIVKEY_LEN];
    
    // user id 8bytes
    memcpy(usrIDAandPrivKey, usrID, XTALK_USRID_LEN);
    // privkey 32 bytes
    memcpy(usrIDAandPrivKey + XTALK_USRID_LEN, privKey, XTALK_PRIVKEY_LEN);
    
    xtalkSHA512(usrIDAandPrivKey, XTALK_USRID_LEN + XTALK_PRIVKEY_LEN, h);
    
    // copy first 2 bytes to chk
    memcpy(chk, h, 2);
    
    // below is the process of E2
    unsigned char salt[8];    // 8*8= 64 bits
    RAND_bytes(salt, 8);
    
    // below is the process of E3
    unsigned char key[256 / 8];
    xtalkPBKDF2_HMAC_SHA512((unsigned char *) pwd, strlen(pwd), salt, 64, key, 256, n);
    
    // below is the process of E4
    unsigned char chkUsrIDPrivKey[2 + XTALK_USRID_LEN + XTALK_PRIVKEY_LEN];    // 2+36+32 = 70
    memcpy(chkUsrIDPrivKey, chk, 2);
    memcpy(chkUsrIDPrivKey + 2, usrID, XTALK_USRID_LEN);
    memcpy(chkUsrIDPrivKey + 2 + XTALK_USRID_LEN, privKey, XTALK_PRIVKEY_LEN);
    
    AES_KEY aes_key;
    if (AES_set_encrypt_key((const unsigned char *) key, sizeof(key) * 8, &aes_key) < 0) {
        assert(false);
        return "error";
    }
    
    unsigned char *secret;
    unsigned char *data_tmp;
    unsigned int ret_len = sizeof(chkUsrIDPrivKey);    // use input data len to get the secret len
    if (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE > 0) {
        ret_len += AES_BLOCK_SIZE - (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE);
    }
    data_tmp = (unsigned char *) malloc(ret_len);
    secret = (unsigned char *) malloc(ret_len);
    memset(data_tmp, 0x00, ret_len);
    memcpy(data_tmp, chkUsrIDPrivKey, sizeof(chkUsrIDPrivKey));    // prepare data for encrypt
    
    for (unsigned int i = 0; i < ret_len / AES_BLOCK_SIZE; i++) {
        unsigned char out[AES_BLOCK_SIZE];
        memset(out, 0, AES_BLOCK_SIZE);
        AES_encrypt((const unsigned char *) (&data_tmp[i * AES_BLOCK_SIZE]), out, &aes_key);
        memcpy(&secret[i * AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_tmp);
    // data stored in secret, length is ret_len
    
    // below is the process of E5
    unsigned char *result;
    result = (unsigned char *) malloc(1 + 8 + ret_len);    // 1 byte version + 8 bytes salt + secret
    
    // set v value;
    result[0] = (ver << 5) + n;
    memcpy(result + 1, salt, 8);
    memcpy(result + 9, secret, ret_len);
    free(secret);    // do not forget to free it.
    
    // finally, we return the hex string. easiler for debug and show
    std::string retStr = HexStr(&result[0], &result[1 + 8 + ret_len], false);
    free(result);
    
    return retStr;
}


using namespace json_spirit;

Value CallRPC(string args);

int signBtcRawTranscation(char *in_param, char **signedtrans_ret) {
    Value r;
    char *ret_str;
    string param = string("signrawtransaction ") + in_param;
    r = CallRPC(param);
    string ret = write_string(Value(r), false);
    ret_str = (char *) malloc(ret.size() + 1);
    sprintf(ret_str, "%s", ret.c_str());
    *signedtrans_ret = ret_str;
    return 0;
}


// add
int GetBtcPrivKeyFromSeedBIP44(const char *SeedStr, char *PrivKey, unsigned int purpose, unsigned int coin, unsigned int account, unsigned int isInternal, unsigned int addrIndex) {
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkey1;
    purpose |= 0x80000000;
    Exkey.Derive(privkey1, purpose);
    
    CExtKey privkey2;
    coin |= 0x80000000;
    privkey1.Derive(privkey2, coin);
    
    CExtKey privkey3;
    account |= 0x80000000;
    privkey2.Derive(privkey3, account);
    
    CExtKey privkey4;
    privkey3.Derive(privkey4, isInternal);
    
    CExtKey privkey5;
    privkey4.Derive(privkey5, addrIndex);
    
    CBitcoinSecret btcSecret;
    btcSecret.SetKey(privkey5.key);
    sprintf(PrivKey, "%s", btcSecret.ToString().c_str());
    
    return 0;
}

int GetBTCPubKeyFromPrivKey(char *privKey, char *pubKey)
{
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if(!btcSecret.SetString (privStr))
    {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CPubKey pubkey  = btcSecret.GetKey().GetPubKey();
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(pubKey,"%s",pubkeyStr.c_str());
    
    return 0;
}

int GetBTCAddrressFromPubKey(char *pubKey, char *address)
{
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    CBitcoinAddress btcAddr(pubkey.GetID());
    sprintf(address,"%s",btcAddr.ToString().c_str());
    
    return 0;
}


- (NSString *)getAddressByPrivKey:(NSString *)prvkey{
    char *cPrivkey = (char *)[prvkey UTF8String];
    char pubKey[128];
    GetBTCPubKeyFromPrivKey(cPrivkey, pubKey);
    char address[128];
    GetBTCAddrressFromPubKey(pubKey, address);
    return [NSString stringWithFormat:@"%s",address];
}

int CheckBtcAddress(char *addr)
{
    CBitcoinAddress address(addr);
    if (!address.IsValid())
    {
        return -1;
    }
    return 0;
}


+(BOOL) checkAddress:(NSString *)address{
    // Adapt the btc.com sweep results
    address = [address stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
    if(address.length == 0){
        return NO;
    }
    char *cAddress = (char *)[address UTF8String];
    int result = CheckBtcAddress(cAddress);
    return result == 0?YES:NO;
}


// use hex string to encrypt wallet
std::string connectWalletEncrypt(char *wallet_HexString, char *pwd, int n, int ver)
{
    std::vector<unsigned char> wallet = ParseHex(wallet_HexString);
    if (wallet.size() == 0)
        return "error wallet lenght";
    //  below is the process of E1
    unsigned char h[64];
    unsigned char chk[2];
    unsigned char plainTextLen = (unsigned char)wallet.size();
    
    xtalkSHA512(&wallet[0], wallet.size(), h);
    
    // copy first 2 bytes to chk
    memcpy(chk, h, 2);
    
    // below is the process of E2
    unsigned char salt[8]; // 8*8= 64 bits
    RAND_bytes(salt, 8);
    
    // below is the process of E3
    unsigned char key[32];
    xtalkPBKDF2_HMAC_SHA512((unsigned char *)pwd, strlen(pwd), salt, 8 * 8, key, sizeof(key) * 8, n);
    
    // below is the process of E4
    unsigned char chkWallet[2 + wallet.size()]; //
    memcpy(chkWallet, chk, 2);
    memcpy(chkWallet + 2, &wallet[0], wallet.size());
    
    AES_KEY aes_key;
    if (AES_set_encrypt_key((const unsigned char *)key, sizeof(key) * 8, &aes_key) < 0)
    {
        assert(false);
        return "error";
    }
    
    unsigned char *secret;
    unsigned char *data_tmp;
    unsigned int ret_len = sizeof(chkWallet); // use input data len to get the secret len
    if (sizeof(chkWallet) % AES_BLOCK_SIZE > 0)
    {
        ret_len += AES_BLOCK_SIZE - (sizeof(chkWallet) % AES_BLOCK_SIZE);
    }
    data_tmp = (unsigned char *)malloc(ret_len);
    secret = (unsigned char *)malloc(ret_len);
    memset(data_tmp, 0x00, ret_len);
    memcpy(data_tmp, chkWallet, sizeof(chkWallet)); // prepare data for encrypt
    
    for (unsigned int i = 0; i < ret_len / AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        memset(out, 0, AES_BLOCK_SIZE);
        AES_encrypt((const unsigned char *)(&data_tmp[i * AES_BLOCK_SIZE]), out, &aes_key);
        memcpy(&secret[i * AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_tmp);
    // data stored in secret, length is ret_len
    
    // below is the process of E5
    unsigned char *result;
    result = (unsigned char *)malloc(1 + 1 + 8 + ret_len); // 1 byte version + 8 bytes salt + secret
    
    // set v value;
    result[0] = (ver << 5) + n;
    result[1] = plainTextLen;
    memcpy(result + 2, salt, 8);
    memcpy(result + 10, secret, ret_len);
    free(secret); // do not forget to free it.
    
    // finally, we return the hex string. easiler for debug and show
    std::string retStr = HexStr(&result[0], &result[1 + 1 + 8 + ret_len], false);
    free(result);
    
    return retStr;
}

// connect wallet decrypt
int connectWalletDecrypt(char *encryptedString, char *pwd, int ver, char *walletHexString){
    int ret;
    
    std::vector<unsigned char> encryptedData = ParseHex(encryptedString);
    // below is the process of D1
    unsigned char v[1];
    v[0] = encryptedData[0];
    
    int version = (v[0] >> 5) & 0x7; // only get the high 3 bits' value
    if (version != ver)
        return -1; // version error
    
    // below is the process of D2
    int n = v[0] & 0x1f; // only get the low 5 bits' value
    
    // below is the process of D3
    int plainTextLen = (int)encryptedData[1];
    unsigned char salt[8];
    unsigned char *secret;
    int secretLen = encryptedData.size() - 1 - 1 - 8; // decrease one byte v and 8 bytes salt
    secret = (unsigned char *)malloc(secretLen);
    memcpy(salt, &encryptedData[2], 8);
    memcpy(secret, &encryptedData[10], secretLen);
    
    // below is the process of D4
    unsigned char key[32];
    xtalkPBKDF2_HMAC_SHA512((unsigned char *)pwd, strlen(pwd), salt, 8 * 8, key, sizeof(key) * 8, n);
    
    // below is the process of D5
    unsigned char *secret_decrypted;
    secret_decrypted = (unsigned char *)malloc(secretLen);
    
    AES_KEY aes_key;
    if (AES_set_decrypt_key(key, sizeof(key) * 8, &aes_key) < 0)
    {
        assert(false);
        return -1;
    }
    
    for (unsigned int i = 0; i < secretLen / AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        AES_decrypt(&secret[AES_BLOCK_SIZE * i], out, &aes_key);
        memcpy(&secret_decrypted[AES_BLOCK_SIZE * i], out, AES_BLOCK_SIZE);
    }
    free(secret);
    
    unsigned char chk[2];
    unsigned char *wallet;
    wallet = (unsigned char *)malloc(plainTextLen);
    memcpy(chk, secret_decrypted, 2);
    memcpy(&wallet[0], secret_decrypted + 2, plainTextLen);
    free(secret_decrypted);
    
    // below is the process of D6
    unsigned char h[64];
    
    xtalkSHA512(&wallet[0], plainTextLen, h);
    
    if (memcmp(chk, h, 2) != 0)
        return 0;
    
    strcpy(walletHexString, HexStr(&wallet[0], &wallet[plainTextLen], false).c_str());
    free(wallet);
    
    return 1;
}

- (NSString *)getCurrencySeedWithBaseSeed:(NSString *)baseSeed{
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d",(int)CurrencyTypeBTC]] lastObject];
    
    /// when create baseSeed ,baseSeed is uppercaseString !!!!
    NSString *btcSeed = [StringTool pinxCreator:baseSeed.uppercaseString withPinv:currencyModel.salt];
    
    return btcSeed;
}


- (NSString *)signRawTranscationWithTvs:(NSString *)tvs category:(CategoryType)category rawTranscation:(NSString *)rawTranscation inputs:(NSArray *)inputs seed:(NSString *)seed{
    switch (category) {
        case CategoryTypeNewUser:
        {
            NSMutableString *mStr = [NSMutableString stringWithFormat:@"currency = %d AND address IN {",(int)CurrencyTypeBTC];
            for (NSString *address in inputs) {
                if ([address isEqualToString:[inputs lastObject]]) {
                    [mStr appendFormat:@"'%@'",address];
                } else {
                    [mStr appendFormat:@"'%@',",address];
                }
            }
            [mStr appendString:@"}"];
            RLMResults *results = [LMCurrencyAddress objectsWhere:mStr];
            NSMutableArray *privkeyArray = [NSMutableArray array];
            for (LMCurrencyAddress *model in results) {
                NSString *inputsPrivkey = [self getPrivkeyBySeed:[self getCurrencySeedWithBaseSeed:seed] index:model.index];
                [privkeyArray addObject:inputsPrivkey];
            }
            NSString *signTransaction = [self signRawTranscationWithTvs:tvs privkeys:privkeyArray rawTranscation:rawTranscation];
            return signTransaction;
        }
            break;
        case CategoryTypeOldUser:
        {
            NSString *signTransaction = [self signRawTranscationWithTvs:tvs privkeys:@[seed] rawTranscation:rawTranscation];
            return signTransaction;
        }
            break;
            
        case CategoryTypeImport:
        {
            NSString *inputsPrivkey = [self getPrivkeyBySeed:seed index:0];
            NSString *signTransaction = [self signRawTranscationWithTvs:tvs privkeys:@[inputsPrivkey] rawTranscation:rawTranscation];
            return signTransaction;
        }
            break;
            
        default:
            return @"";
            break;
    }
    
    return @"";
}

- (NSString *)signRawTranscationWithTvs:(NSString *)tvsJson privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation {
    
    const char *rawtrans_str = [rawTranscation UTF8String];
    char *signedtrans_ret;
    char inparam[1024 * 100];
    
    // Signature parameters json data
    NSMutableString *signParamStr = [NSMutableString stringWithFormat:@"%s", rawtrans_str];
    [signParamStr appendString:@" "];
    [signParamStr appendString:tvsJson];
    [signParamStr appendString:@" "];
    NSString *privKeyJson = [self ObjectTojsonString:privkeys];
    [signParamStr appendString:privKeyJson];
    const char *inparam2 = [signParamStr UTF8String];//sign data
    strcpy(inparam, inparam2);
    
    signBtcRawTranscation(inparam, &signedtrans_ret);
    printf("signRawTranscation=%s\n", signedtrans_ret);
    
    NSString *signedStr = [NSString stringWithFormat:@"%s", signedtrans_ret];
    free(signedtrans_ret);
    NSError *error;
    NSDictionary *completeDic = [NSJSONSerialization JSONObjectWithData:[signedStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    BOOL b = [[completeDic objectForKey:@"complete"] boolValue];
    if (b) {
        NSString *result = [completeDic objectForKey:@"hex"];
        
        return result;
    }
    NSLog(@"signRawTranscation is failure,please check!");
    
    return nil;
    
}
#pragma mark - other methods
/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 */
- (NSArray *)getCurrencyAddressList:(CurrencyType)currency {
    
   LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d",(int)currency]] lastObject];
    NSMutableArray *temArray = [NSMutableArray array];
    for (LMCurrencyAddress *address in currencyModel.addressListArray) {
        [temArray addObject:address.address];
    }
    return temArray.copy;
}
#pragma mark - water methods
- (void)getWaterTransactions:(CurrencyType)currency address:(NSString *)address page:(int)page size:(int)size complete:(void (^)(Transactions *transactions,NSError *error))complete {
    
    if (page == 0) {
        page = 1;
    }
    if (size == 0) {
        size = 10;
    }
    GetTx *requestTranslation = [GetTx new];
    requestTranslation.currency = (int)currency;
    requestTranslation.address = address;
    Pagination *pagination = [Pagination new];
    pagination.page = page;
    pagination.size = size;
    requestTranslation.page = pagination;

    [NetWorkOperationTool POSTWithUrlString:GetWaterTransction postProtoData:requestTranslation.data complete:^(id response) {
        HttpResponse *hRespone = (HttpResponse *)response;
        if (hRespone.code != successCode) {
            if(complete){
                complete(nil,nil);
            }
        }else{
            NSData *data = [ConnectTool decodeHttpResponse:hRespone];
            if (data) {
                Transactions *transations = [Transactions parseFromData:data error:nil];
                if (page == 1) {
                    [[LMHistoryCacheManager sharedManager] cacheTransferContacts:transations.data];
                }
                if (complete) {
                    complete(transations,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if(complete){
            complete(nil,nil);
        }
    }];

}
@end

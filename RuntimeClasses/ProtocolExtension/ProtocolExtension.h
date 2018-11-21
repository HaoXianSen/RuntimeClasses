//
//  ProtocolExtension.h
//  RuntimeClasses
//
//  Created by menglingfeng on 2018/11/21.
//  Copyright © 2018 menglingfeng. All rights reserved.
//  来源参考 https://github.com/forkingdog/ProtocolKit

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define extEnd end

#define extension _protocol_extension

#define _protocol_extension($protocol) _protocol_extension_imp($protocol, _protocol_extension_get_container_class($protocol))

#define _protocol_extension_imp($protocol, $container_class) \
    protocol $protocol; \
    @interface $container_class : NSObject <$protocol> @end \
    @implementation $container_class \
    + (void)load { \
        _protocol_extension_load(@protocol($protocol), $container_class.class); \
    } \

#define _protocol_extension_get_container_class($protocol) _protocol_extension_get_container_class_imp($protocol, __COUNTER__)
#define _protocol_extension_get_container_class_imp($protocol, $counter)  _protocol_extension_get_container_class_name(__EXT_Container_, $protocol, $counter)
#define _protocol_extension_get_container_class_name($a, $b, $c) $a ## $b ## _ ## $c


void _protocol_extension_load(Protocol *protocol, Class container_class);

/* drivers/misc/m0_mods.c
 *
 * European S3 (i9300) specific hacks by gokhanmoral
 * almost no error control. expect panic if you use it on other devices/kernels
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/init.h>
#include <linux/device.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/cpufreq.h>
#include <mach/cpufreq.h>
#include <mach/busfreq.h>
#include <linux/kallsyms.h>
#include <linux/regulator/driver.h>
#include <linux/regulator/machine.h>


struct device **gm_sec_touchscreen;

static ssize_t m0mods_touch_boost_level_write(struct device * dev, struct device_attribute * attr, const char * buf, size_t size)
{
	int lvl;
	int * gm_touch_boost_level;
	gm_touch_boost_level = (int*)(dev_get_drvdata(*gm_sec_touchscreen)) + 71;
    if (sscanf(buf, "%d", &lvl) == 1)
	{
		*gm_touch_boost_level = lvl;
	}
    return size;
}

static ssize_t m0mods_touch_boost_level_read(struct device * dev, struct device_attribute * attr, char * buf)
{
	int * gm_touch_boost_level;
	gm_touch_boost_level = (int*)(dev_get_drvdata(*gm_sec_touchscreen)) + 71;
    return sprintf(buf, "%d\n", *gm_touch_boost_level);
}

static DEVICE_ATTR(touch_boost_level, S_IRUGO | S_IWUGO, m0mods_touch_boost_level_read, m0mods_touch_boost_level_write);

static struct attribute *m0mods_attributes[] = 
    {
	&dev_attr_touch_boost_level.attr,
	NULL
    };

static struct attribute_group m0mods_group = 
    {
	.attrs  = m0mods_attributes,
    };

static struct miscdevice m0mods_device = 
    {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "m0mods",
    };

void create_m0mods_misc_device(void)
{
	int ret;
	
	gm_sec_touchscreen = (
		(struct device**)kallsyms_lookup_name("sec_touchscreen")
		);

    ret = misc_register(&m0mods_device);
    if (ret) return;
    if (sysfs_create_group(&m0mods_device.this_device->kobj, &m0mods_group) < 0) 
		return;
}

static int __init m0mods_init(void)
{
	create_m0mods_misc_device();
    return 0;
}

static void __exit m0mods_exit(void)
{
	return;
}

module_init( m0mods_init );
module_exit( m0mods_exit );

MODULE_AUTHOR("Gokhan Moral <gm@alumni.bilkent.edu.tr>");
MODULE_DESCRIPTION("European i9300 specific hacks");
MODULE_LICENSE("GPL");

package org.example.test.reflection;

import java.io.Serializable;

/**
 *
 * @author ruoyi
 * @date 2020-01-09
 */
public class SysPortal implements Serializable {
	private static final long serialVersionUID = 1L;
	
	/** ID */
	private Integer id;
	/** key */
	private String pkey;
	/** 标题 */
	private String title;
	/** 图标 */
	private String icon;
	/** 模板Url */
	private String url;
	/** 更多url */
	private String moreurl;
	/**
	 * 是否公共模块
	 */
	private Integer commonmodule;
	/**
	 * 启停
	 */
	private Integer active;
	/**
	 * 是否跳转erp
	 */
	private String erpUrl;

	public void setId(Integer id) 
	{
		this.id = id;
	}
	
	public Integer getId() 
	{
		return id;
	}
	public void setPkey(String pkey) 
	{
		this.pkey = pkey;
	}

	public String getPkey() 
	{
		return pkey;
	}
	public void setTitle(String title) 
	{
		this.title = title;
	}

	public String getTitle() 
	{
		return title;
	}
	public void setIcon(String icon) 
	{
		this.icon = icon;
	}

	public String getIcon() 
	{
		return icon;
	}
	public void setUrl(String url) 
	{
		this.url = url;
	}

	public String getUrl() 
	{
		return url;
	}
	public void setMoreurl(String moreurl) 
	{
		this.moreurl = moreurl;
	}

	public String getMoreurl() 
	{
		return moreurl;
	}
	
    public Integer getCommonmodule() {
		return commonmodule;
	}

	public void setCommonmodule(Integer commonmodule) {
		this.commonmodule = commonmodule;
	}
	
	public Integer getActive() {
		return active;
	}

	public void setActive(Integer active) {
		this.active = active;
	}

	public String getErpUrl() {
		return erpUrl;
	}

	public void setErpUrl(String erpUrl) {
		this.erpUrl = erpUrl;
	}

}

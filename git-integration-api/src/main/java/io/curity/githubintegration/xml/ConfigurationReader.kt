/*
 *  Copyright 2022 Curity AB
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package io.curity.githubintegration.xml

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.TextNode
import java.io.StringReader
import java.io.StringWriter
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.OutputKeys
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import javax.xml.xpath.XPath
import javax.xml.xpath.XPathConstants
import javax.xml.xpath.XPathFactory
import java.util.Base64
import org.w3c.dom.Document
import org.w3c.dom.Node
import org.w3c.dom.NodeList
import org.xml.sax.InputSource
import io.curity.githubintegration.errors.ApiError
import org.w3c.dom.Element

/*
 * A utility class to manage parsing and splitting XML
 */
class ConfigurationReader(params: String, values: String) {

    private val paramsDoc: Document
    private val valuesDoc: Document

    init {
        val paramsXml = String(Base64.getDecoder().decode(params))
        paramsDoc = loadDoc(paramsXml)

        val valuesXml = String(Base64.getDecoder().decode(values))
        valuesDoc = loadDoc(valuesXml)
    }

    /*
     * The example uses a base.xml file for this data
     */
    fun getBaseSplitConfiguration(): String {

        val aaaNode = selectChildNode(paramsDoc, "/config/aaa")
        val nacmNode = selectChildNode(paramsDoc, "/config/nacm")
        val xmlText = createOutputXml(listOf(aaaNode, nacmNode))
        return Base64.getEncoder().encodeToString(xmlText.toByteArray())
    }

    /*
     * The example uses an environments.xml file for this data
     */
    fun getEnvironmentsSplitConfiguration(): String {

        val environmentsNode = selectChildNode(paramsDoc, "/config/environments")
        val xmlText = createOutputXml(listOf(environmentsNode))
        return Base64.getEncoder().encodeToString(xmlText.toByteArray())
    }

    /*
     * The example uses a facilities.xml file for this data and removes exported base64 procedures
     * Javascript procedures should be checked directly into Git during development
     */
    fun getFacilitiesSplitConfiguration(): String {

        val facilitiesNode = selectChildNode(paramsDoc, "/config/facilities")
        val processingNode = selectChildNode(paramsDoc, "/config/processing")
        removeChildNode(processingNode, "/config/processing/procedures")

        val xmlText = createOutputXml(listOf(facilitiesNode, processingNode))
        return Base64.getEncoder().encodeToString(xmlText.toByteArray())
    }

    /*
     * The example uses a tokenservice.xml file for this data
     */
    fun getTokenServiceSplitConfiguration(): String {

        val tokenServiceNode = selectChildNode(paramsDoc, "/config/profiles/profile[id='token-service']")
        val xmlText = createOutputXml(listOf(tokenServiceNode), this::addProfileNode)
        return Base64.getEncoder().encodeToString(xmlText.toByteArray())
    }

    /*
     * The example uses an authenticationservice.xml file for this data
     */
    fun getAuthenticationServiceSplitConfiguration(): String {

        val authenticationServiceNode = selectChildNode(paramsDoc, "/config/profiles/profile[id='authentication-service']")
        val xmlText = createOutputXml(listOf(authenticationServiceNode), this::addProfileNode)
        return Base64.getEncoder().encodeToString(xmlText.toByteArray())
    }

    /*
     * Extract environment values that are stored in the Git repo
     * Note that secure values are not stored here and are instead managed in a vault
     */
    fun getEnvironmentSpecificValues(): String {

        val runtimeBaseUrl = selectChildNodeText(valuesDoc, "/config/environments/environment/base-url")
        val dbUsername = selectChildNodeText(valuesDoc, "/config/facilities/data-sources/data-source[id='default-datasource']/jdbc/username")
        val webBaseUrl = selectChildNodeText(valuesDoc, "/config/profiles/profile[id='token-service']/settings/authorization-server/client-store/config-backed/client[id='web-client']/redirect-uris")

        val mapper = ObjectMapper()
        val data = mapper.createObjectNode();
        data.put("RUNTIME_BASE_URL", runtimeBaseUrl);
        data.put("DB_USERNAME", dbUsername);
        data.put("WEB_BASE_URL", webBaseUrl);

        val json = data.toPrettyString()
        return Base64.getEncoder().encodeToString(json.toByteArray())
    }

    /*
     * Load a document from incoming text
     */
    private fun loadDoc(xml: String): Document {

        val builder = DocumentBuilderFactory.newInstance().newDocumentBuilder()

        val stringReader = StringReader(xml)
        stringReader.use {
            return builder.parse(InputSource(stringReader))
        }
    }

    /*
     * Select a child node from an xpath text expression
     */
    private fun selectChildNode(doc: Document, path: String): Node {

        val xPath = XPathFactory.newInstance().newXPath()
        val node = xPath.compile(path).evaluate(doc, XPathConstants.NODE)
            ?: throw ApiError(400, "xpath_not_found", "The path $path was not found in the received XML")

        return node as Node
    }

    /*
     * As above but return a leaf text node
     */
    private fun selectChildNodeText(doc: Document, path: String): String {
        return selectChildNode(doc, path).textContent
    }

    /*
     * Remove a child node that should not be committed to the Git repository
     */
    private fun removeChildNode(parent: Node, path: String) {

        val childNode = selectChildNode(parent.ownerDocument, path)
        parent.removeChild(childNode)
    }

    /*
     * Given some selected nodes, produce an output XML document
     */
    private fun createOutputXml(nodes: List<Node>, setRootElement: ((Element) -> Element)? = null): String {

        // Create and initialize the output document
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument()
        val root = doc.createElement("config")
        root.setAttribute("xmlns", "http://tail-f.com/ns/config/1.0")

        // Add intermediate nodes if needed
        var importRoot = root
        if (setRootElement != null) {
            importRoot = setRootElement(root)
        }

        // Import nodes into the output document
        nodes.forEach {
            val nodeToImport = doc.adoptNode(it.cloneNode(true))
            importRoot.appendChild(nodeToImport)
        }

        // Work around Java whitespace issues
        // https://stackoverflow.com/questions/58478632/how-to-avoid-extra-blank-lines-in-xml-generation-with-java
        val xp: XPath = XPathFactory.newInstance().newXPath()
        val nl = xp.evaluate("//text()[normalize-space(.)='']", root, XPathConstants.NODESET) as NodeList
        for (index in 0 until nl.length) {
            val node = nl.item(index)
            node.parentNode.removeChild(node)
        }

        // Output the data without the XML declaration and use standard 2 character indentation
        val transformer = TransformerFactory.newInstance().newTransformer()
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes")
        transformer.setOutputProperty(OutputKeys.INDENT, "yes")
        transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
        val writer = StringWriter()
        writer.use {
            transformer.transform(DOMSource(root), StreamResult(writer))
            return writer.toString()
        }
    }

    /*
     * Include the profile node under the config node in the output document
     */
    private fun addProfileNode(root: Element): Element {

        val profile = root.ownerDocument.createElement("profiles")
        profile.setAttribute("xmlns", "https://curity.se/ns/conf/base")
        root.appendChild(profile)
        return profile
    }
}

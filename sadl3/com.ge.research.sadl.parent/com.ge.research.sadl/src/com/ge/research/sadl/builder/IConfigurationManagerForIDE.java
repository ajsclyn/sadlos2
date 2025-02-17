
package com.ge.research.sadl.builder;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Map;
import java.util.ServiceLoader;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.ResourceSet;

import com.ge.research.sadl.model.ConceptName;
import com.ge.research.sadl.model.ConceptName.ConceptType;
import com.ge.research.sadl.reasoner.AvailablePlugin;
import com.ge.research.sadl.reasoner.BuiltinInfo;
import com.ge.research.sadl.reasoner.ConfigurationException;
import com.ge.research.sadl.reasoner.ConfigurationItem;
import com.ge.research.sadl.reasoner.IConfigurationManagerForEditing;
import com.ge.research.sadl.reasoner.InvalidNameException;
import com.ge.research.sadl.reasoner.utils.SadlUtils;
import com.ge.research.sadl.reasoner.IConfigurationManagerForEditing.Scope;
import com.hp.hpl.jena.ontology.OntDocumentManager;
import com.hp.hpl.jena.ontology.OntModel;

public interface IConfigurationManagerForIDE extends IConfigurationManagerForEditing {

	public static final String DEFAULTS_PREFIX = "def";

	/**
	 * Call this method to specify the Translator class to use for this model.
	 * 
	 * @param translatorClassName
	 * @return - true if the configuration was updated else false
	 * @throws ConfigurationException 
	 */
	public abstract boolean setTranslatorClassName(String translatorClassName)
			throws ConfigurationException;

	/**
	 * Call this method to specify the Reasoner class to use for this model.
	 * 
	 * @param reasonerClassName
	 * @return - true if the configuration was updated else false
	 */
	public abstract boolean setReasonerClassName(String reasonerClassName);

	/**
	 * Method to determine if the configuration has changed since this ConfigurationManager was initialized.
	 * 
	 * @return true if modified (stale) else false
	 */
	public abstract boolean isConfigurationStale();

	/**
	 * Method to clear an old version of a model from cache when a new version of the model is saved
	 * 
	 * @param newOntModel
	 * @param publicUri
	 * @return - true if removed else false
	 */
	public abstract boolean replaceJenaModelCache(OntModel model,
			String publicUri);

	public abstract boolean resetJena();

	public abstract boolean clearJenaModelContent(OntModel model);

//	/**
//	 * Call this method to add a new mapping or update an existing one for a given altURL. (The assumption is that
//	 * the file name will not change but the model name (uri) may be easily changed.)
//	 * 
//	 * @param altUrl - the actual URL of the OWL file of the model
//	 * @param publicUri - the model name (uri) of the model
//	 * @return -- true if the mappings were changed else false
//	 * @throws MalformedURLException 
//	 * @throws ConfigurationException 
//	 */
//	public abstract boolean addMapping(String altUrl, String publicUri,
//			String globalPrefix) throws MalformedURLException,
//			ConfigurationException;

//	/**
//	 * Call this method to add a new mapping or update an existing one for a given altURL. (The assumption is that
//	 * the file name will not change but the model name (uri) may be easily changed.)
//	 * 
//	 * @param altv - the actual URL of the OWL file of the model
//	 * @param pubv - the model name (uri) of the model
//	 * @return - true if a change was made else false if everything was as needed
//	 * @throws ConfigurationException 
//	 */
//	public abstract boolean addMapping(Resource altv, Resource pubv,
//			Literal prefix) throws ConfigurationException;
//
	/**
	 * Method to add a altUrl<->publicUri mapping to the ont-policy.rdf file.
	 *
	 * @param publicUri
	 * @param altUrl
	 * @param policyFile
	 * @return
	 * @throws IOException
	 * @throws URISyntaxException
	 * @throws ConfigurationException 
	 */
	public abstract boolean addJenaMapping(String publicUri, String altUrl)
			throws IOException, URISyntaxException, ConfigurationException;

	public abstract boolean deleteModel(String publicUri)
			throws ConfigurationException, IOException, URISyntaxException;

	/**
	 * Method to get a list of all the available translator plugins for the current reasoner using a {@link ServiceLoader}
	 * @return A list of all available translator plugins that are compatible (same Reasoner Family) with the current reasoner
	 * @throws ConfigurationException 
	 */
	public abstract List<AvailablePlugin> getAvailableTranslatorPluginsForCurrentReasoner()
			throws ConfigurationException;

	/**
	 * Method to get a list of all the available builtins for the current reasoner using a {@link ServiceLoader}
	 * 
	 * @return A list of all available builtins for the family of the current reasoner
	 * @throws ConfigurationException 
	 */
	public abstract List<BuiltinInfo> getAvailableBuiltinsForCurrentReasoner()
			throws ConfigurationException;

	/**
	 * Method to add a ConfigurationItem to the in-memory configuration model and to the persistent cache.
	 * Note that for items of type Bag (e.g., Builtins) and Sequence, the last element in the array returned
	 * by the call to getCatgegoryHierchy is not a an instance name for a Category but rather the type of the
	 * elements of the Bag or Sequence.
	 * 
	 * @param newItem
	 * @throws ConfigurationException
	 */
	// When adding or updating, we must take the implicit Category hierarchy into account, 
	//	e.g., Builtins is a sub-category of the reasoner's Category instance

	public abstract void addConfiguration(ConfigurationItem newItem)
			throws ConfigurationException;

	/**
	 * Call this method to add or update a ConfigurationItem to the configuration model.
	 * 
	 * @param newItem - the new or update ConfigurationItem
	 * 
	 * @throws ConfigurationException
	 */
	public abstract void updateConfiguration(ConfigurationItem newItem)
			throws ConfigurationException;

	/**
	 * Call this method to save the configuration model to a "configuration.rdf" file in the OwlModels folder.
	 * 
	 * @return - true if successful else false
	 */
	public abstract boolean saveConfiguration();

	public abstract boolean isConfigChanged();

	/**
	 * Call this method to set the mapping for the "defaults.owl" model. This should be called if a default is added
	 * to a model to make sure that the definition of default value concepts is available as an import model.
	 * 
	 * @throws IOException
	 * @throws URISyntaxException
	 * @throws ConfigurationException 
	 */
	public abstract void setDefaultsAltUrlMapping() throws IOException,
			URISyntaxException, ConfigurationException;

	public abstract void setProjectFolderPath(String _projectFolderPath,
			String _modelFolderPath) throws ConfigurationException;

//	public abstract String getProjectFolderPath();

	public abstract void addGlobalPrefix(String modelName, String globalPrefix);

	public abstract String checkForDuplicateSadlFile(URI actualUri) throws URISyntaxException, MalformedURLException;

	public abstract void setProjectFolderPath(String _projectFolderPath);

	/**
	 * Get the concept names of everything in this model with this namespace and matching type
	 * @param localModel
	 * @param modelname
	 * @param cType
	 * @param scope
	 * @return
	 * @throws InvalidNameException
	 */
	public abstract List<ConceptName> getNamedConceptsInModel(
			OntModel localModel, String modelName, ConceptType cType,
			Scope scope) throws InvalidNameException;

	/**
	 * Method to get the Jena OntDocumentManager 
	 */
	public abstract OntDocumentManager getJenaDocumentMgr();

	/**
	 * Method to determine if a particular model, identified by public URI, is derived
	 * from translating a SADL model file.
	 * 
	 * @param publicUri
	 * @return
	 * @throws ConfigurationException 
	 * @throws MalformedURLException 
	 */
	public abstract boolean isSadlDerivedPublicUri(String publicUri) throws ConfigurationException, MalformedURLException;

	/**
	 * Method to determine if a particular model, identified by actual URL, is derived
	 * from translating a SADL model file.
	 * 
	 * @param altUrl
	 * @return
	 * @throws ConfigurationException 
	 * @throws MalformedURLException 
	 */
	public abstract boolean isSadlDerivedAltUrl(URI altUrl) throws ConfigurationException, MalformedURLException;

	/**
	 * Method to find the imports, with prefixes, for a given model identified by uri
	 * @param publicUri
	 * @param scope -- Scope.LOCALONLY or Scope.INCLUDEIMPORTS
	 * @return
	 * @throws ConfigurationException 
	 * @throws IOException 
	 */
	public abstract Map<String, String> getImports(String publicUri, Scope scope) throws ConfigurationException, IOException;

	/**
	 * Get the concept names of everything in the named model matching type and scope
	 * @param localModel
	 * @param publicUri
	 * @param cType
	 * @param scope
	 * @return
	 * @throws InvalidNameException
	 * @throws ConfigurationException 
	 */
	public abstract List<ConceptName> getNamedConceptsInModel(String publicUri, 
			ConceptType cType, Scope scope) throws InvalidNameException, ConfigurationException, IOException;
	
	/**
	 * Gets the URI of a SADL resource for a public URI.
	 * @param publicUri The public URI
	 * @return Sadl resource URI, or <code>null</code>.
	 * @throws ConfigurationException
	 * @throws IOException
	 */
	public abstract URI getSadlUriFromPublicUri (ResourceSet resourceSet, URI publicUri) throws ConfigurationException, IOException;
	
	/**
	 * Get a SadlUtils instance.
	 * @return
	 */
	public abstract SadlUtils getSadlUtils();
	
	/**
	 * Call this method to validate that an OWL model being imported actually exists (is valid)
	 * @param publicUri
	 * @param altUrl
	 * @return
	 * @throws MalformedURLException 
	 */
	public abstract boolean validateImport(String publicUri, String altUrl) throws MalformedURLException;

	/**
	 * Call this method to set the mapping for the "SadlServicesConfigurationConcepts.owl" model. This should be called if a default is added
	 * to a model to make sure that the definition of default value concepts is available as an import model.
	 * 
	 * @throws IOException
	 * @throws URISyntaxException
	 * @throws ConfigurationException 
	 */
	public abstract void setServicesConfigurationAltUrlMapping()
			throws IOException, URISyntaxException, ConfigurationException;
	
	/**
	 * Call this method to get a list of the actual URLs (as class URI) of all RDF and OWL
	 * models that should be available to the project but are not actually in the project
	 * or projects upon which this project depends.
	 * @return
	 */
	public abstract List<URI> getExternalModelURIs();

	/**
	 * Call this method to add a new mapping or update an existing one for a given altURL. (The assumption is that
	 * the file name will not change but the model name (uri) may be easily changed.)
	 * 
	 * @param mappings -- list of String[] where each element of the list contains: 0-altUrl, 1-publicUri, 2-global prefix
	 * @param bKeepPrefix -- if true keep the old prefix even if other things change
	 * @param source -- an identifier of what created the mapping, e.g., SADL
	 * @return -- true if the mappings were changed else false
	 * @throws ConfigurationException 
	 * @throws URISyntaxException 
	 * @throws IOException 
	 */
	public abstract boolean addMappings(List<String[]> mappings, boolean bKeepPrefix, String source) throws ConfigurationException, IOException, URISyntaxException;
	/**
	 * Call this method to get an OntModel from a URI (or URL)
	 * 
	 * @param publicUri--URI of model (will also work with actual URL)
	 * @param scope--Scope.LOCALONLY or Scope.INCLUDEIMPORTS
	 * @return
	 * @throws ConfigurationException
	 * @throws IOException
	 */
	public abstract OntModel getOntModel(String publicUri, Scope scope) throws ConfigurationException, IOException;

	/**
	 * Call this method to find a file treating it first as an absolute path and that failing as a project-relative path
	 * @param fn
	 * @return
	 */
	public abstract File resolveFilename(String fn);
}
/************************************************************************
 * Copyright © 2007-2016 - General Electric Company, All Rights Reserved
 *
 * Project: SADL
 *
 * Description: The Semantic Application Design Language (SADL) is a
 * language for building semantic models and expressing rules that
 * capture additional domain knowledge. The SADL-IDE (integrated
 * development environment) is a set of Eclipse plug-ins that
 * support the editing and testing of semantic models using the
 * SADL language.
 *
 * This software is distributed "AS-IS" without ANY WARRANTIES
 * and licensed under the Eclipse Public License - v 1.0
 * which is available at http://www.eclipse.org/org/documents/epl-v10.php
 *
 ***********************************************************************/
/*
 * generated by Xtext 2.9.0-SNAPSHOT
 */
package com.ge.research.sadl.ui.contentassist

import com.ge.research.sadl.model.DeclarationExtensions
import com.ge.research.sadl.model.OntConceptType
import com.ge.research.sadl.processing.OntModelProvider
import com.ge.research.sadl.processing.SadlConstants
import com.ge.research.sadl.sADL.BinaryOperation
import com.ge.research.sadl.sADL.Declaration
import com.ge.research.sadl.sADL.Name
import com.ge.research.sadl.sADL.PropOfSubject
import com.ge.research.sadl.sADL.SadlModel
import com.ge.research.sadl.sADL.SadlProperty
import com.ge.research.sadl.sADL.SadlPropertyInitializer
import com.ge.research.sadl.sADL.SadlResource
import com.ge.research.sadl.sADL.SadlSimpleTypeReference
import com.ge.research.sadl.sADL.SubjHasProp
import com.google.common.base.Predicate
import com.google.inject.Inject
import com.hp.hpl.jena.ontology.OntResource
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.GrammarUtil
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import com.ge.research.sadl.sADL.SadlRangeRestriction
import com.hp.hpl.jena.vocabulary.XSD

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class SADLProposalProvider extends AbstractSADLProposalProvider {
	@Inject protected DeclarationExtensions declarationExtensions
	@Inject extension ProposalProviderFilterProvider;
	
	val PropertyRangeKeywords = newArrayList(
		'string','boolean','decimal','int','long','float','double','duration','dateTime','time','date',
    	'gYearMonth','gYear','gMonthDay','gDay','gMonth','hexBinary','base64Binary','anyURI',
    	'integer','negativeInteger','nonNegativeInteger','positiveInteger','nonPositiveInteger', 
    	'byte','unsignedByte','unsignedInt','anySimpleType','data','class')
	
	protected List<OntConceptType> typeRestrictions
	protected List<String> excludedNamespaces
	
	override void completeSadlModel_BaseUri(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		var rsrcNm = context.resource.URI.lastSegment
		var proposal = "\"http://sadl.org/" + rsrcNm + "\""
		acceptor.accept(createCompletionProposal(proposal, context))
	}
	
	override void completeSadlModel_Alias(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		var rsrcNm = context.resource.URI.trimFileExtension.lastSegment
		var proposal = rsrcNm
		acceptor.accept(createCompletionProposal(proposal, context))
		
	}
	
	override def void completeSadlImport_ImportedResource(EObject model,  Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		val term = assignment.terminal
		val container = EcoreUtil2.getContainerOfType(model, SadlModel)
		
// When there is a partial statement of the form "import ", cursor at end, the call on the next line results in a NullPointerException and no proposals are generated.		
//		val imports = container.imports.map[importedResource.baseUri].toSet
		
// An alternative for the above is the code below, up to the call to lookupCrossReference, which has sufficient not null checks to work
		val imports = new ArrayList<String>()
		val importsList = container.imports
		if (importsList != null) {
			for (imp:importsList) {
				if (imp != null) {
					val import = imp.importedResource
					if (import != null) {
						val impUri = import.baseUri
						if (impUri != null) {
							imports.add(impUri)
						}
					}
				}
			}
		}

		lookupCrossReference(term as CrossReference, context, acceptor, new Predicate<IEObjectDescription>() {
					override apply(IEObjectDescription input) {
						val fnm = input.EObjectURI.lastSegment
						if (fnm != null && (fnm.toLowerCase().endsWith(".sadl") || 
							fnm.toLowerCase().endsWith(".owl") ||
							 fnm.toLowerCase().endsWith(".n3") || 
							 fnm.toLowerCase().endsWith(".ntriple") ||
							 fnm.toLowerCase().endsWith(".nt")) && 
							!fnm.equals("SadlImplicitModel.sadl") &&
							!fnm.equals("SadlBuiltinFunctions.sadl") && 
							!imports.contains(input.name.toString)
						) {
							return true;
						}
						return false
					}
					
				})
	}

	// Creates a proposal for an EOS terminal.  Xtext can't guess (at
    // the moment) what the valid values for a terminal rule are, so
    // that's why there is no automatic content assist for EOS.
	override void complete_EOS(EObject model, RuleCall ruleCall, 
	        ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		var proposalText = ".\n";
		var displayText = ". - End of Sentence";
		var image = getImage(model);
		var proposal = createCompletionProposal(proposalText, displayText, image, context);
		acceptor.accept(proposal);
	}

	override void completeKeyword(Keyword keyword, ContentAssistContext context,
			ICompletionProposalAcceptor acceptor) {
		if (!includeKeyword(keyword, context)) {
			return
		}
		var proposalText = keyword.getValue();
		if (isInvokedDirectlyAfterKeyword(context) && requireSpaceBefore(keyword, context) && !hasSpaceBefore(context)) {
			proposalText = " " + proposalText;
		}
		if (requireSpaceAfter(keyword, context) && !hasSpaceAfter(context)) {
			proposalText = proposalText + " ";
		}
	
		var proposal = createCompletionProposal(proposalText, getKeywordDisplayString(keyword),
				getImage(keyword), context);
		getPriorityHelper().adjustKeywordPriority(proposal, context.getPrefix());
		acceptor.accept(proposal);
	}
	

	override void createProposals(ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		if (excludedNamespaces != null) excludedNamespaces.clear
		if (typeRestrictions != null) typeRestrictions.clear
		super.createProposals(context, acceptor)
	}
	
//	// this is without filtering out duplicates
//	override void lookupCrossReference(CrossReference crossReference, ContentAssistContext context,
//			ICompletionProposalAcceptor acceptor) {
//		lookupCrossReference(crossReference, context, acceptor,
//				Predicates.<IEObjectDescription> alwaysTrue());
//	}

	// this is with filtering out of duplicates
	/**
	 * Method to lookup cross reference but eliminating duplicates. A given SadlResource will appear twice, 
	 * once as an unqualified name, e.g., "foo" and once as a qualified name, e.g., "ns1:foo".
	 * If multiple imports contain a SadlResource with the same localname but in different namespaces, 
	 * then there will be a "foo", "ns1:foo" in one import and a "foo", "ns2:foo" in another. If this
	 * happens then we want to include the qualified name (apply return true) otherwise the unqualified name.
	 */
	override void lookupCrossReference(CrossReference crossReference, ContentAssistContext context,
				ICompletionProposalAcceptor acceptor) {
		val criterable = getFilteredCrossReferenceList(crossReference, context)		//Iterable<IEObjectDescription>
		val itr = criterable.iterator
				
		val pm = context.previousModel
		val cm = context.currentModel
//		displayModel(pm, "Previous")
//		displayModel(cm, "Current")
		if (pm != null) {
			if (pm instanceof Declaration) {
				val declcontainer = (pm as Declaration).eContainer
				if (declcontainer != null && declcontainer instanceof SubjHasProp) {
					val sadlprop = (declcontainer as SubjHasProp).prop
					restrictTypeToClass(sadlprop)
				}
			}
			else if (pm instanceof SubjHasProp) {
				restrictTypeToAllPropertyTypes
			}
			else if (pm instanceof PropOfSubject && (pm as PropOfSubject).left != null) {
				val prop = (pm as PropOfSubject).left
				if ((pm as PropOfSubject).right != null && (pm as PropOfSubject).right instanceof Declaration) {
					if (((pm as PropOfSubject).right as Declaration).type != null) {
						excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
						restrictTypeToAllPropertyTypes
					}
					else {
						excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
						restrictTypeToClass(prop as SadlResource)
					}
				}
				else if (prop instanceof Name) {
					excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
					restrictTypeToClassPlusVars((prop as Name).name)
				}
				else if (prop instanceof SadlResource) {
					excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
					restrictTypeToClassPlusVars(prop as SadlResource)	
				}
				else if (prop instanceof Declaration) {
					excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
					restrictTypeToAllPropertyTypes
				}
			}
			else if (pm instanceof SadlResource && cm != null && cm.eContainer instanceof SadlModel) {
				// just a name on a new line--can't be followed by another name
				return
			}
			else if (pm instanceof BinaryOperation) {
				val left = (pm as BinaryOperation).left
				val op = (pm as BinaryOperation).op
				val right = (pm as BinaryOperation).right
				if (op.equals("is")) {
					if (left instanceof Name) {
						val ltype = declarationExtensions.getOntConceptType(left as Name)
						if (ltype.equals(OntConceptType.VARIABLE)) {
							// no restrictions
							excludeNamespace(SadlConstants.SADL_BASE_MODEL_URI)
						}
					}
				}
			}
			else if (pm instanceof SadlPropertyInitializer) {
				if ((pm as SadlPropertyInitializer).property == null) {
					excludeNamespace(SadlConstants.SADL_IMPLICIT_MODEL_URI)
					restrictTypeToAllPropertyTypes
				}
				else {
					// values of the property
					
				}
			}
			else {
				val container = pm.eContainer
				if (container instanceof SubjHasProp) {
					restrictTypeToAllPropertyTypes
				}
				else if (container instanceof SadlProperty) {
					val propsr = (container as SadlProperty).nameOrRef
					restrictTypeToClass(propsr)
				}
			}
		}
		
		val nmMap = new HashMap<String, QualifiedName>		// a map of qualified names with simple name as key, qualified name as value
		val qnmList = new ArrayList<QualifiedName>
		val eliminatedNames = new ArrayList<String>			// simple names of SadlReferences that require a qualified name
		try {
			if (!itr.empty) {
				while (!itr.empty) {
					val nxt = itr.next
					if (nxt.qualifiedName.segmentCount > 1) {
						val nm = nxt.qualifiedName.lastSegment
						if (nmMap.containsKey(nm) && !nxt.qualifiedName.equals(nmMap.get(nm))) {
							// we already have a qname with the same local name 
							qnmList.add(nxt.qualifiedName)
							if (!qnmList.contains(nmMap.get(nm))) {
								qnmList.add(nmMap.get(nm))
							}
							eliminatedNames.add(nxt.qualifiedName.lastSegment)
						}
						else {
							nmMap.put(nxt.name.lastSegment, nxt.qualifiedName)
						}
					}
				}			
			}
		}
		catch (Throwable t) {
			t.printStackTrace
		}
		
		lookupCrossReference(crossReference, context, acceptor,new Predicate<IEObjectDescription>() {
				override apply(IEObjectDescription input) {
					val element = input.EObjectOrProxy
					if (typeRestrictions != null && typeRestrictions.size > 0) {
						if (element instanceof SadlResource) {
							val eltype = declarationExtensions.getOntConceptType(element as SadlResource)
							if (!typeRestrictions.contains(eltype)) {
								return false;
							}
						}
					}
					if (excludedNamespaces != null) {
						if (element instanceof SadlResource) {
							val uri = declarationExtensions.getConceptUri(element as SadlResource)
							for (ens:excludedNamespaces) {
								if (uri.startsWith(ens)) {
									return false;
								}
							}
						}
					}
					val isQName = input.qualifiedName.segmentCount > 1
					if (isQName) {
						if (qnmList.contains(input.name)) {
							// qnmList only contains qualified names that are ambiguous so return true for this qualified name
							return true
						}
						else {
							return false
						}
					}
					val nm = input.name.lastSegment
					if (eliminatedNames.contains(nm)) {
						return false;
					}
					return  context.crossReferenceFilter.apply(input);
				}
			})
	}
	
	def boolean includeKeyword(Keyword keyword, ContentAssistContext context) {
		var model = context.currentModel
		if (model == null) {
			model = context.previousModel
		}
		if (model != null) {
			if (model instanceof Declaration) { return false}
			val container = model.eContainer
			val kval = keyword.value
			if (container instanceof SadlProperty) {
				if (model instanceof SadlRangeRestriction) {
					val ge = context.lastCompleteNode.grammarElement
					if (ge instanceof Keyword && (ge as Keyword).value.equals("type")) {
						if (PropertyRangeKeywords.contains(kval)) {
							return true
						}
						else {
							return false
						}
					}
				}
				return true
			}
			else if (container instanceof Declaration) {
				if (kval.equals("with") ||
					kval.equals("only") ||
					kval.equals("when") ||
					kval.equals("where")
				) {
					return true
				}
				else {
					return false
				}
			}
			else if (container instanceof SubjHasProp) {
				if ((container as SubjHasProp).prop != null) {
					if ((container as SubjHasProp).right == null) {
						// this is ready for a value but doesn't have one yet
						if (kval.equals("(") ||
							kval.equals("[") ||
							kval.equals("{")
						) {
							return true;
						}
						else {
							return false;
						}
					} else if ((container as SubjHasProp).right instanceof Name) {
						val valnm =((container as SubjHasProp).right as Name)
						if (declarationExtensions.isProperty(valnm)) {
							if (!kval.equals("of")) {
								return false
							}
							return true
						}
					}
				}
			}
			if (model instanceof Name) {
				if (declarationExtensions.isProperty(model as Name)) {
					if (!kval.equals("of")) {
						return false
					}
				}
			}
			else if (model instanceof PropOfSubject) {
				val lcn = context.lastCompleteNode
				val lcnText = lcn.text
				if (lcnText.equals("a")) {
					return false
				}
				if (kval.equals("(")
				) {
					return true
				}
				return false
			}
			else if (model instanceof SadlPropertyInitializer) {
				if (kval.equals("true") || kval.equals("false") || kval.equals("PI") || kval.equals("e")) {
					val proptype = declarationExtensions.getOntConceptType((model as SadlPropertyInitializer).property)
					if (proptype.equals(OntConceptType.DATATYPE_PROPERTY)) {
						// check property range
						val ontModel = OntModelProvider.find(model.eResource)
						if (ontModel != null) {
							val ontprop = ontModel.getOntProperty(declarationExtensions.getConceptUri((model as SadlPropertyInitializer).property))
							if (ontprop != null) {
								val rnglst = ontprop.listRange
								if (rnglst != null) {
									if (kval.equals("true") || kval.equals("false")) {
										while (rnglst.hasNext) {
											val rng = rnglst.next
											if (rng.equals(XSD.xboolean)) {
												rnglst.close
												return true
											}
										}
									}
									else {
										while (rnglst.hasNext) {
											val rng = rnglst.next
											if (rng.equals(XSD.decimal) || rng.equals(XSD.xdouble) || rng.equals(XSD.xfloat)) {
												rnglst.close
												return true
											}
										}
									}
								}
							}
						}
					}
				}
				return false;
			}	
		}
		return true
	}
	
	def void displayModel(EObject object, String label) {
		System.out.println(label + ": " + object.class.canonicalName)
		if (object instanceof SadlResource) {
			System.out.println(declarationExtensions.getConceptUri(object as SadlResource))
			System.out.println(declarationExtensions.getOntConceptType(object as SadlResource))
		}
		else if (object instanceof SubjHasProp) {
			displayModel((object as SubjHasProp).left, "SubjHasProp left")
			displayModel((object as SubjHasProp).prop, "SubHasProp prop")
			displayModel((object as SubjHasProp).right, "SubjHasProp right")
		}
	}
	
	def excludeNamespace(String nsuri) {
		if (excludedNamespaces == null) {
			val ens = new ArrayList<String>
			excludedNamespaces = ens
		}
		if (!excludedNamespaces.contains(nsuri)) {
			excludedNamespaces.add(nsuri)
		}
	}
	
	def restrictTypeToClassPlusVars(SadlResource resource) {
		restrictTypeToClass(resource)
		if (typeRestrictions != null) {
			typeRestrictions.add(OntConceptType.VARIABLE)
		}
		else {
			val typeList = new ArrayList<OntConceptType>
			typeList.add(OntConceptType.VARIABLE)
			typeRestrictions = typeList
		}
	}
	
	def restrictTypeToClass(SadlResource propsr) {
		// only classes in the domain of the property
		if (propsr != null) {
			// for now just filter to classes
			val typeList = new ArrayList<OntConceptType>
			typeList.add(OntConceptType.CLASS)
			typeRestrictions = typeList
		}
	}
	
	/**
	 * Method to determine if a particular SadlResource (OntConceptType.INSTANCE, OntConceptType.CLASS, or OntConceptType.VARIABLE)
	 * is in the domain of the given property
	 */
	def boolean isSadlResourceInDomainOfProperty(SadlResource propsr, SadlResource sr) {
			val om = OntModelProvider.find(propsr.eResource)
			if (om != null) {
				val p = om.getProperty(declarationExtensions.getConceptUri(propsr))
				if (p != null) {
					val srtype = declarationExtensions.getOntConceptType(sr)
					var OntResource ontrsrc
					if (srtype.equals(OntConceptType.CLASS)) {
						ontrsrc = om.getOntClass(declarationExtensions.getConceptUri(sr))
					}
					else if (srtype.equals(OntConceptType.INSTANCE)) {
						ontrsrc = om.getIndividual(declarationExtensions.getConceptUri(sr))
					}
					else if (srtype.equals(OntConceptType.VARIABLE)) {
						//TBD
					}
//					return JenaBasedSadlModelValidator.checkPropertyDomain(om, p, ontrsrc, propsr.eContainer, false)
				}
			}
		
		return false
	}
	
	def restrictTypeToAllPropertyTypes() {
				val typeList = new ArrayList<OntConceptType>
				typeList.add(OntConceptType.ANNOTATION_PROPERTY)
				typeList.add(OntConceptType.CLASS_PROPERTY)
				typeList.add(OntConceptType.DATATYPE_PROPERTY)
				typeList.add(OntConceptType.RDF_PROPERTY)
				typeRestrictions = typeList
	}
	
	def addRestrictionType(OntConceptType type) {
		if (typeRestrictions == null) {
			typeRestrictions = new ArrayList<OntConceptType>
		}
		typeRestrictions.add(type)
	}
	
	def getFilteredCrossReferenceList(CrossReference crossReference, ContentAssistContext context) {
		val containingParserRule = GrammarUtil.containingParserRule(crossReference);	// ParserRule
		if (!GrammarUtil.isDatatypeRule(containingParserRule)) {
			if (containingParserRule.isWildcard()) {
				// TODO we need better ctrl flow analysis here
				// The cross reference may come from another parser rule then the current model 
				val ref = GrammarUtil.getReference(crossReference, context.getCurrentModel().eClass());
				if (ref != null) {
					val scope = getScopeProvider().getScope(context.currentModel, ref) as IScope;	//IScope
					return scope.allElements
				}
			} else {
				if (context.currentModel instanceof SadlSimpleTypeReference) {
					return emptyList;
				}
				val ref = GrammarUtil.getReference(crossReference);
				if (ref != null) {
					val scope = getScopeProvider().getScope(context.currentModel, ref) as IScope;	//IScope
					return scope.allElements
				}
			}
		}
		return null
	}
	
	def isInvokedDirectlyAfterKeyword (ContentAssistContext context) {
		return context.getLastCompleteNode().getTotalEndOffset()==context.getOffset();
	}
	
	def requireSpaceBefore (Keyword keyword, ContentAssistContext context) {
//		if (!keywordsWithSpaceBefore.contains(keyword)) {
//			return false;
//		}
		return true;
	}
	
	def hasSpaceBefore (ContentAssistContext context) {
		//TODO: Detect space before invocation offset
		return false;
	}
	
	def requireSpaceAfter (Keyword keyword, ContentAssistContext context) {
//		if (!keywordsWithSpaceAfter.contains(keyword)) {
//			return false;
//		}
		return true;
	}
	
	def boolean hasSpaceAfter (ContentAssistContext context) {
		if (!context.getCurrentNode().hasNextSibling()) return false; // EOF
		//TODO: Detect space after invocation offset
		return false;
	}
	
}

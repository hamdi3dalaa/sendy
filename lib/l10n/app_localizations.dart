import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sendy'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Sendy'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numero de telephone'**
  String get phoneNumber;

  /// No description provided for @verifyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Verifier le telephone'**
  String get verifyPhone;

  /// No description provided for @enterOTP.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code OTP'**
  String get enterOTP;

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Verifier'**
  String get verify;

  /// No description provided for @orders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// No description provided for @newOrder.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get newOrder;

  /// No description provided for @acceptOrder.
  ///
  /// In fr, this message translates to:
  /// **'Accepter la commande'**
  String get acceptOrder;

  /// No description provided for @trackDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Suivre la livraison'**
  String get trackDelivery;

  /// No description provided for @orderAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Commande acceptee'**
  String get orderAccepted;

  /// No description provided for @orderInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours de livraison'**
  String get orderInProgress;

  /// No description provided for @orderDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livre'**
  String get orderDelivered;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @deliveryPerson.
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get deliveryPerson;

  /// No description provided for @restaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get admin;

  /// No description provided for @selectUserType.
  ///
  /// In fr, this message translates to:
  /// **'Selectionnez le type d\'utilisateur'**
  String get selectUserType;

  /// No description provided for @uploadID.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger la carte d\'identite'**
  String get uploadID;

  /// No description provided for @waitingApproval.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'approbation'**
  String get waitingApproval;

  /// No description provided for @approved.
  ///
  /// In fr, this message translates to:
  /// **'Approuve'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejete'**
  String get rejected;

  /// No description provided for @myLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get myLocation;

  /// No description provided for @deliveryLocation.
  ///
  /// In fr, this message translates to:
  /// **'Position du livreur'**
  String get deliveryLocation;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Methode de paiement'**
  String get paymentMethod;

  /// No description provided for @cashOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Paiement a la livraison'**
  String get cashOnDelivery;

  /// No description provided for @cardPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement par carte'**
  String get cardPayment;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientot disponible'**
  String get comingSoon;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get deliveryFee;

  /// No description provided for @serviceFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de service'**
  String get serviceFee;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @addComment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un commentaire'**
  String get addComment;

  /// No description provided for @commentPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Instructions speciales pour votre commande...'**
  String get commentPlaceholder;

  /// No description provided for @placeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Passer la commande'**
  String get placeOrder;

  /// No description provided for @invoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get invoice;

  /// No description provided for @downloadInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger la facture'**
  String get downloadInvoice;

  /// No description provided for @orderDetails.
  ///
  /// In fr, this message translates to:
  /// **'Details de la commande'**
  String get orderDetails;

  /// No description provided for @clientComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire du client'**
  String get clientComment;

  /// No description provided for @dhs.
  ///
  /// In fr, this message translates to:
  /// **'DHs'**
  String get dhs;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @myOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes Commandes'**
  String get myOrders;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @searchRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un restaurant...'**
  String get searchRestaurants;

  /// No description provided for @searchRestaurantsAndDishes.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher restaurants et plats...'**
  String get searchRestaurantsAndDishes;

  /// No description provided for @restaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @featuredRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants populaires'**
  String get featuredRestaurants;

  /// No description provided for @allRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Tous les restaurants'**
  String get allRestaurants;

  /// No description provided for @noRestaurantsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun restaurant disponible'**
  String get noRestaurantsAvailable;

  /// No description provided for @restaurantsWillAppear.
  ///
  /// In fr, this message translates to:
  /// **'Les restaurants apparaitront ici une fois approuves'**
  String get restaurantsWillAppear;

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun resultat trouve'**
  String get noResultsFound;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre terme de recherche'**
  String get tryAnotherSearch;

  /// No description provided for @discoverRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Decouvrez nos restaurants'**
  String get discoverRestaurants;

  /// No description provided for @tapToLoadRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le bouton pour charger les restaurants disponibles'**
  String get tapToLoadRestaurants;

  /// No description provided for @loadRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Charger les restaurants'**
  String get loadRestaurants;

  /// No description provided for @loadingRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des restaurants...'**
  String get loadingRestaurants;

  /// No description provided for @dishes.
  ///
  /// In fr, this message translates to:
  /// **'plats'**
  String get dishes;

  /// No description provided for @dish.
  ///
  /// In fr, this message translates to:
  /// **'plat'**
  String get dish;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @myCart.
  ///
  /// In fr, this message translates to:
  /// **'Mon Panier'**
  String get myCart;

  /// No description provided for @emptyCart.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get emptyCart;

  /// No description provided for @addDishesToOrder.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des plats pour commander'**
  String get addDishesToOrder;

  /// No description provided for @viewMenu.
  ///
  /// In fr, this message translates to:
  /// **'Voir le menu'**
  String get viewMenu;

  /// No description provided for @deliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get deliveryAddress;

  /// No description provided for @enterFullAddress.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse complete...'**
  String get enterFullAddress;

  /// No description provided for @commentOptional.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (optionnel)'**
  String get commentOptional;

  /// No description provided for @specialInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Instructions speciales, allergies...'**
  String get specialInstructions;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Resume'**
  String get summary;

  /// No description provided for @pay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get pay;

  /// No description provided for @enterDeliveryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre adresse de livraison'**
  String get enterDeliveryAddress;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Commande passee avec succes!'**
  String get orderPlacedSuccess;

  /// No description provided for @addedToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au panier'**
  String get addedToCart;

  /// No description provided for @removedFromCart.
  ///
  /// In fr, this message translates to:
  /// **'Retire du panier'**
  String get removedFromCart;

  /// No description provided for @perUnit.
  ///
  /// In fr, this message translates to:
  /// **'/ unite'**
  String get perUnit;

  /// No description provided for @noDishesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plat disponible'**
  String get noDishesAvailable;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Reessayer'**
  String get retry;

  /// No description provided for @noOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande'**
  String get noOrders;

  /// No description provided for @ordersWillAppear.
  ///
  /// In fr, this message translates to:
  /// **'Vos commandes apparaitront ici'**
  String get ordersWillAppear;

  /// No description provided for @orderNumber.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get orderNumber;

  /// No description provided for @articles.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get articles;

  /// No description provided for @article.
  ///
  /// In fr, this message translates to:
  /// **'article'**
  String get article;

  /// No description provided for @others.
  ///
  /// In fr, this message translates to:
  /// **'autres'**
  String get others;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'autre'**
  String get other;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptee'**
  String get accepted;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @delivered.
  ///
  /// In fr, this message translates to:
  /// **'Livree'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulee'**
  String get cancelled;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Francais'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get arabic;

  /// No description provided for @switchLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get switchLanguage;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Parametres'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Deconnexion'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous deconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @noFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori'**
  String get noFavorites;

  /// No description provided for @favoritesWillAppear.
  ///
  /// In fr, this message translates to:
  /// **'Vos restaurants favoris apparaitront ici'**
  String get favoritesWillAppear;

  /// No description provided for @rateOrder.
  ///
  /// In fr, this message translates to:
  /// **'Evaluer la commande'**
  String get rateOrder;

  /// No description provided for @rateYourExperience.
  ///
  /// In fr, this message translates to:
  /// **'Evaluez votre experience'**
  String get rateYourExperience;

  /// No description provided for @writeReview.
  ///
  /// In fr, this message translates to:
  /// **'Ecrire un avis (optionnel)'**
  String get writeReview;

  /// No description provided for @submitReview.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre l\'avis'**
  String get submitReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Avis soumis avec succes!'**
  String get reviewSubmitted;

  /// No description provided for @reviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviews;

  /// No description provided for @noReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis'**
  String get noReviews;

  /// No description provided for @savedAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses enregistrees'**
  String get savedAddresses;

  /// No description provided for @addAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get editAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'adresse'**
  String get deleteAddress;

  /// No description provided for @addressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'adresse (ex: Maison, Bureau)'**
  String get addressLabel;

  /// No description provided for @addressDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Adresse supprimee'**
  String get addressDeleted;

  /// No description provided for @selectAddress.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une adresse'**
  String get selectAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une nouvelle adresse'**
  String get addNewAddress;

  /// No description provided for @noSavedAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse enregistree'**
  String get noSavedAddresses;

  /// No description provided for @promoCode.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get promoCode;

  /// No description provided for @enterPromoCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code promo'**
  String get enterPromoCode;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @promoApplied.
  ///
  /// In fr, this message translates to:
  /// **'Code promo applique!'**
  String get promoApplied;

  /// No description provided for @discount.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get discount;

  /// No description provided for @removePromo.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le code promo'**
  String get removePromo;

  /// No description provided for @promotions.
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @trackOrder.
  ///
  /// In fr, this message translates to:
  /// **'Suivre la commande'**
  String get trackOrder;

  /// No description provided for @estimatedDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison estimee'**
  String get estimatedDelivery;

  /// No description provided for @arrivingIn.
  ///
  /// In fr, this message translates to:
  /// **'Arrive dans ~{minutes} min'**
  String arrivingIn(Object minutes);

  /// No description provided for @orderPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Commande passee'**
  String get orderPlaced;

  /// No description provided for @orderPickedUp.
  ///
  /// In fr, this message translates to:
  /// **'Commande recuperee'**
  String get orderPickedUp;

  /// No description provided for @onTheWay.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get onTheWay;

  /// No description provided for @callDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le livreur'**
  String get callDelivery;

  /// No description provided for @deliveryPersonName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du livreur'**
  String get deliveryPersonName;

  /// No description provided for @deliveryPersonPhone.
  ///
  /// In fr, this message translates to:
  /// **'Tel du livreur'**
  String get deliveryPersonPhone;

  /// No description provided for @locationInitializing.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation de la localisation...'**
  String get locationInitializing;

  /// No description provided for @locationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de localisation'**
  String get locationError;

  /// No description provided for @deliverySpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace Livreur'**
  String get deliverySpace;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get unavailable;

  /// No description provided for @canReceiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez recevoir des commandes'**
  String get canReceiveOrders;

  /// No description provided for @activateToReceiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Activez pour recevoir des commandes'**
  String get activateToReceiveOrders;

  /// No description provided for @currentPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position actuelle'**
  String get currentPosition;

  /// No description provided for @positionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Position requise'**
  String get positionRequired;

  /// No description provided for @positionRequiredDescription.
  ///
  /// In fr, this message translates to:
  /// **'La localisation est necessaire pour recevoir des commandes'**
  String get positionRequiredDescription;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les parametres'**
  String get openSettings;

  /// No description provided for @restaurantSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace Restaurant'**
  String get restaurantSpace;

  /// No description provided for @myMenu.
  ///
  /// In fr, this message translates to:
  /// **'Mon Menu'**
  String get myMenu;

  /// No description provided for @manageMenu.
  ///
  /// In fr, this message translates to:
  /// **'Gerer le menu'**
  String get manageMenu;

  /// No description provided for @createMenu.
  ///
  /// In fr, this message translates to:
  /// **'Creer mon menu'**
  String get createMenu;

  /// No description provided for @noMenuItems.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plat dans votre menu'**
  String get noMenuItems;

  /// No description provided for @startAddingDishes.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par ajouter vos plats'**
  String get startAddingDishes;

  /// No description provided for @approvedItems.
  ///
  /// In fr, this message translates to:
  /// **'Approuves'**
  String get approvedItems;

  /// No description provided for @pendingItems.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingItems;

  /// No description provided for @rejectedItems.
  ///
  /// In fr, this message translates to:
  /// **'Rejetes'**
  String get rejectedItems;

  /// No description provided for @availableItems.
  ///
  /// In fr, this message translates to:
  /// **'disponibles'**
  String get availableItems;

  /// No description provided for @pendingApprovalWarning.
  ///
  /// In fr, this message translates to:
  /// **'en attente d\'approbation'**
  String get pendingApprovalWarning;

  /// No description provided for @rejectedWarning.
  ///
  /// In fr, this message translates to:
  /// **'Verifiez les raisons'**
  String get rejectedWarning;

  /// No description provided for @adminPanel.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de Bord Admin'**
  String get adminPanel;

  /// No description provided for @manageApprovalsAndConfig.
  ///
  /// In fr, this message translates to:
  /// **'Gerer les approbations et configurations'**
  String get manageApprovalsAndConfig;

  /// No description provided for @pendingUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs en attente'**
  String get pendingUsers;

  /// No description provided for @deliveryPersons.
  ///
  /// In fr, this message translates to:
  /// **'Livreurs'**
  String get deliveryPersons;

  /// No description provided for @pendingDishes.
  ///
  /// In fr, this message translates to:
  /// **'Plats en attente'**
  String get pendingDishes;

  /// No description provided for @dishesToValidate.
  ///
  /// In fr, this message translates to:
  /// **'plats a valider'**
  String get dishesToValidate;

  /// No description provided for @appConfig.
  ///
  /// In fr, this message translates to:
  /// **'Configuration App'**
  String get appConfig;

  /// No description provided for @appConfigSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Twilio, OTP, et autres parametres'**
  String get appConfigSubtitle;

  /// No description provided for @totalPending.
  ///
  /// In fr, this message translates to:
  /// **'Total en attente'**
  String get totalPending;

  /// No description provided for @noActiveOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande active'**
  String get noActiveOrders;

  /// No description provided for @ordersSection.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get ordersSection;

  /// No description provided for @acceptedOrders.
  ///
  /// In fr, this message translates to:
  /// **'Acceptees'**
  String get acceptedOrders;

  /// No description provided for @inDelivery.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get inDelivery;

  /// No description provided for @fastFood.
  ///
  /// In fr, this message translates to:
  /// **'Fast Food'**
  String get fastFood;

  /// No description provided for @moroccan.
  ///
  /// In fr, this message translates to:
  /// **'Marocain'**
  String get moroccan;

  /// No description provided for @pizza.
  ///
  /// In fr, this message translates to:
  /// **'Pizza'**
  String get pizza;

  /// No description provided for @sushi.
  ///
  /// In fr, this message translates to:
  /// **'Sushi'**
  String get sushi;

  /// No description provided for @burger.
  ///
  /// In fr, this message translates to:
  /// **'Burger'**
  String get burger;

  /// No description provided for @chicken.
  ///
  /// In fr, this message translates to:
  /// **'Poulet'**
  String get chicken;

  /// No description provided for @tacos.
  ///
  /// In fr, this message translates to:
  /// **'Tacos'**
  String get tacos;

  /// No description provided for @desserts.
  ///
  /// In fr, this message translates to:
  /// **'Desserts'**
  String get desserts;

  /// No description provided for @recentSearches.
  ///
  /// In fr, this message translates to:
  /// **'Recherches recentes'**
  String get recentSearches;

  /// No description provided for @menuManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du Menu'**
  String get menuManagement;

  /// No description provided for @addDish.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un plat'**
  String get addDish;

  /// No description provided for @noDishesInMenu.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plat dans le menu'**
  String get noDishesInMenu;

  /// No description provided for @addFirstDish.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier plat'**
  String get addFirstDish;

  /// No description provided for @noDishesInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plat dans cette categorie'**
  String get noDishesInCategory;

  /// No description provided for @confirmDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeletion;

  /// No description provided for @confirmDeleteDishMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer \"{name}\" ?'**
  String confirmDeleteDishMessage(String name);

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @dishDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Plat supprime avec succes'**
  String get dishDeletedSuccess;

  /// No description provided for @noPendingDishes.
  ///
  /// In fr, this message translates to:
  /// **'Aucun plat en attente'**
  String get noPendingDishes;

  /// No description provided for @pendingStatusLabel.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get pendingStatusLabel;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Categorie'**
  String get category;

  /// No description provided for @createdOn.
  ///
  /// In fr, this message translates to:
  /// **'Cree le'**
  String get createdOn;

  /// No description provided for @tapToEnlarge.
  ///
  /// In fr, this message translates to:
  /// **'Toucher l\'image pour agrandir'**
  String get tapToEnlarge;

  /// No description provided for @noImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image'**
  String get noImage;

  /// No description provided for @imageLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get imageLoadError;

  /// No description provided for @noImageWarning.
  ///
  /// In fr, this message translates to:
  /// **'Ce plat n\'a pas d\'image. Recommande de demander au restaurant d\'en ajouter une.'**
  String get noImageWarning;

  /// No description provided for @confirmApproval.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'approbation'**
  String get confirmApproval;

  /// No description provided for @confirmApproveDish.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous approuver ce plat ?'**
  String get confirmApproveDish;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get reject;

  /// No description provided for @dishApprovedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Plat approuve avec succes'**
  String get dishApprovedSuccess;

  /// No description provided for @dishRejected.
  ///
  /// In fr, this message translates to:
  /// **'Plat rejete'**
  String get dishRejected;

  /// No description provided for @rejectDish.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter le plat'**
  String get rejectDish;

  /// No description provided for @rejectionReason.
  ///
  /// In fr, this message translates to:
  /// **'Raison du rejet *'**
  String get rejectionReason;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Image de mauvaise qualite, titre inapproprie...'**
  String get rejectionReasonHint;

  /// No description provided for @enterReason.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une raison'**
  String get enterReason;

  /// No description provided for @dishName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du plat *'**
  String get dishName;

  /// No description provided for @descriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Description *'**
  String get descriptionRequired;

  /// No description provided for @priceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prix (DHs) *'**
  String get priceRequired;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @pendingApprovalNote.
  ///
  /// In fr, this message translates to:
  /// **'(En attente d\'approbation)'**
  String get pendingApprovalNote;

  /// No description provided for @enterNameValidation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom'**
  String get enterNameValidation;

  /// No description provided for @nameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 3 caracteres'**
  String get nameTooShort;

  /// No description provided for @enterDescriptionValidation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une description'**
  String get enterDescriptionValidation;

  /// No description provided for @descriptionTooShort.
  ///
  /// In fr, this message translates to:
  /// **'La description doit contenir au moins 10 caracteres'**
  String get descriptionTooShort;

  /// No description provided for @enterPriceValidation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un prix'**
  String get enterPriceValidation;

  /// No description provided for @invalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get invalidPrice;

  /// No description provided for @pricePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le prix doit etre superieur a 0'**
  String get pricePositive;

  /// No description provided for @dishAddedPending.
  ///
  /// In fr, this message translates to:
  /// **'Plat ajoute ! En attente d\'approbation par l\'admin.'**
  String get dishAddedPending;

  /// No description provided for @unknownError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get unknownError;

  /// No description provided for @addTheDish.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le plat'**
  String get addTheDish;

  /// No description provided for @dishVerificationNote.
  ///
  /// In fr, this message translates to:
  /// **'Votre plat sera verifie par un administrateur avant d\'etre publie.'**
  String get dishVerificationNote;

  /// No description provided for @chooseImage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get chooseImage;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chooseFromGallery;

  /// No description provided for @editDish.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le plat'**
  String get editDish;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @newPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle photo'**
  String get newPhoto;

  /// No description provided for @newPhotoPending.
  ///
  /// In fr, this message translates to:
  /// **'La nouvelle photo sera en attente d\'approbation'**
  String get newPhotoPending;

  /// No description provided for @dishModifiedPending.
  ///
  /// In fr, this message translates to:
  /// **'Plat modifie ! Nouvelle photo en attente d\'approbation.'**
  String get dishModifiedPending;

  /// No description provided for @dishModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Plat modifie avec succes !'**
  String get dishModifiedSuccess;

  /// No description provided for @modificationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la modification'**
  String get modificationError;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @userNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: Utilisateur non connecte'**
  String get userNotConnected;

  /// No description provided for @reason.
  ///
  /// In fr, this message translates to:
  /// **'Raison'**
  String get reason;

  /// No description provided for @manageMyMenu.
  ///
  /// In fr, this message translates to:
  /// **'Gerer mon menu'**
  String get manageMyMenu;

  /// No description provided for @deliveryService.
  ///
  /// In fr, this message translates to:
  /// **'Service de livraison'**
  String get deliveryService;

  /// No description provided for @invoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'FACTURE'**
  String get invoiceTitle;

  /// No description provided for @clientInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations Client'**
  String get clientInfo;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Telephone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @articleHeader.
  ///
  /// In fr, this message translates to:
  /// **'Article'**
  String get articleHeader;

  /// No description provided for @qty.
  ///
  /// In fr, this message translates to:
  /// **'Qte'**
  String get qty;

  /// No description provided for @unitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Unit.'**
  String get unitPrice;

  /// No description provided for @paymentMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMode;

  /// No description provided for @cashOnDeliveryInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Especes a la livraison'**
  String get cashOnDeliveryInvoice;

  /// No description provided for @cardPaymentInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get cardPaymentInvoice;

  /// No description provided for @thankYou.
  ///
  /// In fr, this message translates to:
  /// **'Merci d\'avoir choisi Sendy!'**
  String get thankYou;

  /// No description provided for @promoMinOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande minimum: {amount} DHs'**
  String promoMinOrder(String amount);

  /// No description provided for @promoExpired.
  ///
  /// In fr, this message translates to:
  /// **'Code promo expire'**
  String get promoExpired;

  /// No description provided for @promoInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code promo invalide'**
  String get promoInvalid;

  /// No description provided for @validationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de validation'**
  String get validationError;

  /// No description provided for @profileImage.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get profileImage;

  /// No description provided for @restaurantLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo du restaurant'**
  String get restaurantLogo;

  /// No description provided for @changeLogo.
  ///
  /// In fr, this message translates to:
  /// **'Changer le logo'**
  String get changeLogo;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo de profil'**
  String get changeProfilePhoto;

  /// No description provided for @uploadLogo.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger le logo'**
  String get uploadLogo;

  /// No description provided for @uploadPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Telecharger la photo'**
  String get uploadPhoto;

  /// No description provided for @imageUploadSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Image envoyee ! En attente d\'approbation par l\'admin.'**
  String get imageUploadSuccess;

  /// No description provided for @imageUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi de l\'image'**
  String get imageUploadError;

  /// No description provided for @pendingImageApproval.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle image en attente d\'approbation'**
  String get pendingImageApproval;

  /// No description provided for @pendingImageChanges.
  ///
  /// In fr, this message translates to:
  /// **'Changements d\'images en attente'**
  String get pendingImageChanges;

  /// No description provided for @approveImage.
  ///
  /// In fr, this message translates to:
  /// **'Approuver l\'image'**
  String get approveImage;

  /// No description provided for @rejectImage.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter l\'image'**
  String get rejectImage;

  /// No description provided for @imageApproved.
  ///
  /// In fr, this message translates to:
  /// **'Image approuvee avec succes'**
  String get imageApproved;

  /// No description provided for @imageRejected.
  ///
  /// In fr, this message translates to:
  /// **'Image rejetee'**
  String get imageRejected;

  /// No description provided for @currentImage.
  ///
  /// In fr, this message translates to:
  /// **'Image actuelle'**
  String get currentImage;

  /// No description provided for @newImage.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle image'**
  String get newImage;

  /// No description provided for @noProfileImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo de profil'**
  String get noProfileImage;

  /// No description provided for @invoiceHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des factures'**
  String get invoiceHistory;

  /// No description provided for @totalRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenu total'**
  String get totalRevenue;

  /// No description provided for @totalOrders.
  ///
  /// In fr, this message translates to:
  /// **'Total commandes'**
  String get totalOrders;

  /// No description provided for @totalDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Total livraisons'**
  String get totalDeliveries;

  /// No description provided for @deliveryEarnings.
  ///
  /// In fr, this message translates to:
  /// **'Gains de livraison'**
  String get deliveryEarnings;

  /// No description provided for @orderDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de commande'**
  String get orderDate;

  /// No description provided for @noInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get noInvoices;

  /// No description provided for @invoicesWillAppear.
  ///
  /// In fr, this message translates to:
  /// **'Les factures apparaitront ici'**
  String get invoicesWillAppear;

  /// No description provided for @period.
  ///
  /// In fr, this message translates to:
  /// **'Periode'**
  String get period;

  /// No description provided for @allTime.
  ///
  /// In fr, this message translates to:
  /// **'Tout le temps'**
  String get allTime;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @from.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get from;

  /// No description provided for @to.
  ///
  /// In fr, this message translates to:
  /// **'A'**
  String get to;

  /// No description provided for @generateReport.
  ///
  /// In fr, this message translates to:
  /// **'Generer le rapport'**
  String get generateReport;

  /// No description provided for @ordersSummary.
  ///
  /// In fr, this message translates to:
  /// **'Resume des commandes'**
  String get ordersSummary;

  /// No description provided for @deliverySummary.
  ///
  /// In fr, this message translates to:
  /// **'Resume des livraisons'**
  String get deliverySummary;

  /// No description provided for @adminEmailConfig.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Email Admin'**
  String get adminEmailConfig;

  /// No description provided for @adminEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email admin'**
  String get adminEmail;

  /// No description provided for @emailNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications par email'**
  String get emailNotifications;

  /// No description provided for @newJoinRequest.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande d\'inscription'**
  String get newJoinRequest;

  /// No description provided for @menuItemUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mise a jour du menu'**
  String get menuItemUpdate;

  /// No description provided for @imageChangeRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demande de changement d\'image'**
  String get imageChangeRequest;

  /// No description provided for @orderFood.
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get orderFood;

  /// No description provided for @mySpace.
  ///
  /// In fr, this message translates to:
  /// **'Mon Espace'**
  String get mySpace;

  /// No description provided for @administration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @restaurantAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du restaurant'**
  String get restaurantAddressLabel;

  /// No description provided for @cityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get cityLabel;

  /// No description provided for @useGPS.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le GPS'**
  String get useGPS;

  /// No description provided for @gpsPositionCaptured.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS capturee !'**
  String get gpsPositionCaptured;

  /// No description provided for @availableOrders.
  ///
  /// In fr, this message translates to:
  /// **'Livraisons'**
  String get availableOrders;

  /// No description provided for @noAvailableOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison disponible'**
  String get noAvailableOrders;

  /// No description provided for @ordersWillAppearHere.
  ///
  /// In fr, this message translates to:
  /// **'Les commandes apparaitront ici'**
  String get ordersWillAppearHere;

  /// No description provided for @acceptDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Accepter la livraison'**
  String get acceptDelivery;

  /// No description provided for @confirmAcceptDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la livraison'**
  String get confirmAcceptDelivery;

  /// No description provided for @confirmAcceptDeliveryMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous accepter cette livraison ?'**
  String get confirmAcceptDeliveryMessage;

  /// No description provided for @orderAcceptedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Livraison acceptee !'**
  String get orderAcceptedSuccess;

  // Restaurant incoming orders
  String get incomingOrders;
  String get noIncomingOrders;
  String get confirmAcceptOrderMessage;
  String get orderAcceptedByRestaurant;
  String get rejectOrder;
  String get rejectOrderMessage;
  String get orderRejectedSuccess;
  String get noOrdersInYourCity;
  String get chooseLanguage;

  // Delivery active order
  String get activeDelivery;
  String get confirmDelivery;
  String get confirmDeliveryMessage;
  String get markAsDelivered;
  String get deliveryCompleted;
  String get callClient;

  // Resume active delivery
  String get resumeDelivery;
  String get youHaveActiveDelivery;
  String get tapToResume;

  // Delivery fees admin
  String get deliveryFeesTitle;
  String get searchByNameOrPhone;
  String get noDeliveryPersonsFound;
  String get totalDeliveryPersons;
  String get overThreshold;
  String get totalOwed;
  String get amountDue;
  String get deliveryFeesSubtitle;

  // Settlement system
  String get serviceFeeBalance;
  String get amountOwedToSendy;
  String get settlementRequired;
  String get sendPayment;
  String get amountToSend;
  String get uploadProofInstructions;
  String get tapToUploadProof;
  String get proofDescription;
  String get sending;
  String get settlementSent;
  String get pendingSettlements;
  String get noSettlementsPending;
  String get settlementsToReview;
  String get confirmApproval;
  String confirmSettlementApproval(String amount);
  String get settlementApproved;
  String get rejectSettlement;
  String get rejectSettlementMessage;
  String get rejectionReason;
  String get settlementRejected;
  String get approve;
  String get reject;

  // Dish promotions
  String get dishPromotions;
  String get managePromotions;
  String get addPromotion;
  String get noPromotions;
  String get addPromotionHint;
  String get selectDish;
  String get promoPrice;
  String get startDate;
  String get endDate;
  String get invalidPromoPrice;
  String get invalidPromoDates;
  String get promotionAdded;
  String get confirmDeletePromoMessage;
  String get currentPromotions;
  String get expired;
  String get upcoming;
  String get active;
  String get minimumDiscountError;

  // Delivery map
  String get myPositionMap;
  String get tapToExpandMap;
  String get tapToShrinkMap;

  // Restaurant availability
  String get restaurantOpen;
  String get restaurantClosed;
  String get restaurantReceivingOrders;
  String get restaurantNotReceivingOrders;
  String get workingHours;
  String get notConfigured;
  String get openTime;
  String get closeTime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

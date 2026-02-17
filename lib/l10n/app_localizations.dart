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
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// No description provided for @verifyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le téléphone'**
  String get verifyPhone;

  /// No description provided for @enterOTP.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code OTP'**
  String get enterOTP;

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
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
  /// **'Commande acceptée'**
  String get orderAccepted;

  /// No description provided for @orderInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours de livraison'**
  String get orderInProgress;

  /// No description provided for @orderDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livré'**
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

  /// No description provided for @selectUserType.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez le type d\'utilisateur'**
  String get selectUserType;

  /// No description provided for @uploadID.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger la carte d\'identité'**
  String get uploadID;

  /// No description provided for @waitingApproval.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'approbation'**
  String get waitingApproval;

  /// No description provided for @approved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
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
  /// **'Méthode de paiement'**
  String get paymentMethod;

  /// No description provided for @cashOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get cashOnDelivery;

  /// No description provided for @cardPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement par carte'**
  String get cardPayment;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
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
  /// **'Instructions spéciales pour votre commande...'**
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
  /// **'Télécharger la facture'**
  String get downloadInvoice;

  /// No description provided for @orderDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la commande'**
  String get orderDetails;

  /// No description provided for @clientComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire du client'**
  String get clientComment;

  /// No description provided for @dhs.
  ///
  /// In fr, this message translates to:
  /// **'DH'**
  String get dhs;

  String get home;
  String get search;
  String get myOrders;
  String get profile;
  String get searchRestaurants;
  String get searchRestaurantsAndDishes;
  String get restaurants;
  String get categories;
  String get featuredRestaurants;
  String get allRestaurants;
  String get noRestaurantsAvailable;
  String get restaurantsWillAppear;
  String get noResultsFound;
  String get tryAnotherSearch;
  String get discoverRestaurants;
  String get tapToLoadRestaurants;
  String get loadRestaurants;
  String get loadingRestaurants;
  String get dishes;
  String get dish;
  String get all;
  String get myCart;
  String get emptyCart;
  String get addDishesToOrder;
  String get viewMenu;
  String get deliveryAddress;
  String get enterFullAddress;
  String get commentOptional;
  String get specialInstructions;
  String get summary;
  String get pay;
  String get enterDeliveryAddress;
  String get orderPlacedSuccess;
  String get addedToCart;
  String get removedFromCart;
  String get perUnit;
  String get noDishesAvailable;
  String get error;
  String get retry;
  String get noOrders;
  String get ordersWillAppear;
  String get orderNumber;
  String get articles;
  String get article;
  String get others;
  String get other;
  String get pending;
  String get accepted;
  String get inProgress;
  String get delivered;
  String get cancelled;
  String get language;
  String get french;
  String get arabic;
  String get switchLanguage;
  String get settings;
  String get logout;
  String get logoutConfirm;
  String get cancel;
  String get favorites;
  String get addToFavorites;
  String get removeFromFavorites;
  String get noFavorites;
  String get favoritesWillAppear;
  String get rateOrder;
  String get rateYourExperience;
  String get writeReview;
  String get submitReview;
  String get reviewSubmitted;
  String get reviews;
  String get noReviews;
  String get savedAddresses;
  String get addAddress;
  String get editAddress;
  String get deleteAddress;
  String get addressLabel;
  String get addressDeleted;
  String get selectAddress;
  String get addNewAddress;
  String get noSavedAddresses;
  String get promoCode;
  String get enterPromoCode;
  String get apply;
  String get promoApplied;
  String get discount;
  String get removePromo;
  String get promotions;
  String get trackOrder;
  String get estimatedDelivery;
  String arrivingIn(String minutes);
  String get orderPlaced;
  String get orderPickedUp;
  String get onTheWay;
  String get callDelivery;
  String get deliveryPersonName;
  String get deliveryPersonPhone;
  String get locationInitializing;
  String get locationError;
  String get deliverySpace;
  String get available;
  String get unavailable;
  String get canReceiveOrders;
  String get activateToReceiveOrders;
  String get currentPosition;
  String get positionRequired;
  String get positionRequiredDescription;
  String get refresh;
  String get openSettings;
  String get restaurantSpace;
  String get myMenu;
  String get manageMenu;
  String get createMenu;
  String get noMenuItems;
  String get startAddingDishes;
  String get approvedItems;
  String get pendingItems;
  String get rejectedItems;
  String get availableItems;
  String get pendingApprovalWarning;
  String get rejectedWarning;
  String get adminPanel;
  String get manageApprovalsAndConfig;
  String get pendingUsers;
  String get deliveryPersons;
  String get pendingDishes;
  String get dishesToValidate;
  String get appConfig;
  String get appConfigSubtitle;
  String get totalPending;
  String get noActiveOrders;
  String get ordersSection;
  String get acceptedOrders;
  String get inDelivery;
  String get fastFood;
  String get moroccan;
  String get pizza;
  String get sushi;
  String get burger;
  String get chicken;
  String get tacos;
  String get desserts;
  String get recentSearches;
  String get admin;
  String get menuManagement;
  String get addDish;
  String get noDishesInMenu;
  String get addFirstDish;
  String get noDishesInCategory;
  String get confirmDeletion;
  String confirmDeleteDishMessage(String name);
  String get delete;
  String get dishDeletedSuccess;
  String get noPendingDishes;
  String get pendingStatusLabel;
  String get description;
  String get price;
  String get category;
  String get createdOn;
  String get tapToEnlarge;
  String get noImage;
  String get imageLoadError;
  String get noImageWarning;
  String get confirmApproval;
  String get confirmApproveDish;
  String get approve;
  String get reject;
  String get dishApprovedSuccess;
  String get dishRejected;
  String get rejectDish;
  String get rejectionReason;
  String get rejectionReasonHint;
  String get enterReason;
  String get dishName;
  String get descriptionRequired;
  String get priceRequired;
  String get addPhoto;
  String get pendingApprovalNote;
  String get enterNameValidation;
  String get nameTooShort;
  String get enterDescriptionValidation;
  String get descriptionTooShort;
  String get enterPriceValidation;
  String get invalidPrice;
  String get pricePositive;
  String get dishAddedPending;
  String get unknownError;
  String get addTheDish;
  String get dishVerificationNote;
  String get chooseImage;
  String get takePhoto;
  String get chooseFromGallery;
  String get editDish;
  String get changePhoto;
  String get newPhoto;
  String get newPhotoPending;
  String get dishModifiedPending;
  String get dishModifiedSuccess;
  String get modificationError;
  String get saveChanges;
  String get userNotConnected;
  String get reason;
  String get manageMyMenu;
  String get deliveryService;
  String get invoiceTitle;
  String get clientInfo;
  String get name;
  String get phone;
  String get address;
  String get articleHeader;
  String get qty;
  String get unitPrice;
  String get paymentMode;
  String get cashOnDeliveryInvoice;
  String get cardPaymentInvoice;
  String get thankYou;
  String promoMinOrder(String amount);
  String get promoExpired;
  String get promoInvalid;
  String get validationError;

  // Profile image strings
  String get profileImage;
  String get restaurantLogo;
  String get changeLogo;
  String get changeProfilePhoto;
  String get uploadLogo;
  String get uploadPhoto;
  String get imageUploadSuccess;
  String get imageUploadError;
  String get pendingImageApproval;
  String get pendingImageChanges;
  String get approveImage;
  String get rejectImage;
  String get imageApproved;
  String get imageRejected;
  String get currentImage;
  String get newImage;
  String get noProfileImage;

  // Invoice history strings
  String get invoiceHistory;
  String get totalRevenue;
  String get totalOrders;
  String get totalDeliveries;
  String get deliveryEarnings;
  String get orderDate;
  String get noInvoices;
  String get invoicesWillAppear;
  String get period;
  String get allTime;
  String get thisMonth;
  String get thisWeek;
  String get today;
  String get from;
  String get to;
  String get generateReport;
  String get ordersSummary;
  String get deliverySummary;

  // Admin email strings
  String get adminEmailConfig;
  String get adminEmail;
  String get emailNotifications;
  String get newJoinRequest;
  String get menuItemUpdate;
  String get imageChangeRequest;
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
